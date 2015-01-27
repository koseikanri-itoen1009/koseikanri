CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO011A01C(body)
 * Description      : 発注依頼からの要求に従って、物件を各種作業に割当可能かチェックを行い、
 *                    その結果を発注依頼に返します。
 * MD.050           : MD050_CSO_011_A01_作業依頼（発注依頼）時のインストールベースチェック機能
 *
 * Version          : 1.38
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      初期処理(A-1)
 *  get_requisition_info      発注依頼情報抽出(A-2)
 *  input_check               入力チェック処理(A-3)
 *  check_ib_existence        物件マスタ存在チェック処理(A-4)
 *  chk_authorization_status  購買依頼ステータスチェック処理(A-5-0)
 *  check_ib_info             設置用物件情報チェック処理(A-5)
 *  check_withdraw_ib_info    引揚用物件情報チェック処理(A-6)
 *  check_ablsh_appl_ib_info  廃棄申請用物件情報チェック処理(A-7)
 *  check_ablsh_aprv_ib_info  廃棄決裁用物件情報チェック処理(A-8)
 *  check_mvmt_in_shp_ib_info 店内移動用物件情報チェック処理(A-9)
 *  check_object_status       物件ステータスチェック処理(A-10)
 *  check_syozoku_mst         所属マスタ存在チェック処理(A-11)
 *  check_cust_mst            顧客マスタ存在チェック処理(A-12)
 *  check_dclr_place_mst      申告地マスタ存在チェック処理(A-27)
 *  lock_ib_info              物件ロック処理(A-13)
 *  update_ib_info            設置用物件更新処理(A-14)
 *  update_withdraw_ib_info   引揚用物件更新処理(A-15)
 *  update_abo_appl_ib_info   廃棄申請用物件更新処理(A-16)
 *  update_abo_aprv_ib_info   廃棄決裁用物件更新処理(A-17)
 *  chk_wk_req_proc           作業依頼／発注情報連携対象テーブル存在チェック処理(A-18)
 *  insert_wk_req_proc        作業依頼／発注情報連携対象テーブル登録処理(A-19)
 *  update_wk_req_proc        作業依頼／発注情報連携対象テーブル更新処理(A-20)
 *  start_approval_wf_proc    承認ワークフロー起動(エラー通知)(A-21)
 *  verifyauthority           承認者権限（製品）チェック(A-22)
 *  update_po_req_line        発注依頼明細更新処理(A-23)
 *  check_maker_code          メーカーコードチェック処理(A-24)
 *  check_business_low_type   業態(小分類)チェック処理(A-25)
 *  submain                   メイン処理プロシージャ
 *  main_for_application      メイン処理（発注依頼申請用）
 *  main_for_approval         メイン処理（発注依頼承認用）
 *  main_for_denegation       メイン処理（発注依頼否認用）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   N.Yabuki         新規作成
 *  2009-03-05    1.1   N.Yabuki         結合障害対応(不具合ID.46)
 *                                       ・カテゴリ区分がNULL(営業TM以外)の場合、後続処理をスキップする処理を追加
 *  2009-04-02    1.2   N.Yabuki         【ST障害対応177】顧客ステータスチェックに「25：SP承認済」を追加
 *  2009-04-03    1.3   N.Yabuki         【ST障害対応297】経費購買品（カテゴリ区分がNULL）を抽出対象外に修正
 *  2009-04-06    1.4   N.Yabuki         【ST障害対応101】作業依頼／発注情報連携対象テーブルの存在チェック、更新処理追加
 *  2009-04-10    1.5   D.Abe            【ST障害対応108】エラー通知の起動処理を追加。
 *  2009-04-13    1.6   N.Yabuki         【ST障害対応170】作業希望日と依頼日のチェック追加
 *                                       【ST障害対応171】設置場所区分が「1:屋外」の場合、設置場所階数不要のチェック追加
 *                                       【ST障害対応198】リース情報のチェックをリース区分が「1:自社リース」時のみに修正
 *                                       【ST障害対応527】引揚時の設置作業会社、事業所のチェックを削除
 *  2009-04-16    1.7   N.Yabuki         【ST障害対応398】否認時にIBの作業依頼中フラグをOFFにする処理を追加
 *                                       【ST障害対応549】廃棄申請時の機器状態３、廃棄フラグ更新処理のタイミング変更
 *  2009-04-27    1.8   N.Yabuki         【ST障害対応505】引揚物件、店内移動物件と設置先_顧客コードの紐付けチェックを追加
 *                                       【ST障害対応517】顧客マスタ存在チェック処理を修正
 *  2009-05-01    1.9   Tomoko.Mori      T1_0897対応
 *  2009-05-11    1.10  D.Abe            【ST障害対応965】廃棄申請時の機器状態３、廃棄フラグ更新処理のタイミング変更
 *  2009-05-15    1.11  D.Abe            【ST障害対応669】承認者権限（製品）チェックを追加
 *  2009-07-01    1.12  D.Abe            【ST障害対応529】発注明細の取引性質を更新するように変更
 *  2009-07-08    1.13  D.Abe            【0000464】品目カテゴリと機種コードのメーカーチェックを追加
 *  2009-07-14    1.14  K.Satomura       【0000476】機器状態２の故障中を4から9へ変更
 *  2009-07-16    1.15  K.Hosoi          【0000375,0000419】
 *  2009-08-10    1.16  K.Satomura       【0000662】顧客担当営業員存在チェックをコメントアウト
 *  2009-09-10    1.17  K.Satomura       【0001335】顧客チェックを顧客区分によって変更するよう修正
 *  2009-11-25    1.18  K.Satomura       【E_本稼動_00027】MC、MC候補をエラーとするよう修正
 *  2009-11-30    1.19  K.Satomura       【E_本稼動_00204】作業希望日のチェックを一時的に外す
 *  2009-11-30    1.20  T.Maruyama       【E_本稼動_00119】チェック強化対応
 *  2009-12-07    1.21  K.Satomura       【E_本稼動_00336】E_本稼動_00204の対応を元に戻す
 *  2009-12-09    1.22  K.Satomura       【E_本稼動_00341】承認時のチェックを申請時のチェックと同様にする
 *  2009-12-16    1.23  D.Abe            【E_本稼動_00354】廃棄決済でリース物件存在チェック対応
 *                                       【E_本稼動_00498】リース物件ステータスの「再リース待ち」対応
 *  2009-12-24    1.24  D.Abe            【E_本稼動_00563】暫定対応（機種コード、メーカーコードの日付条件を削除）
 *  2009-12-24    1.25  K.Hosoi          【E_本稼動_00563】設置先顧客名、設置先_郵便番号、設置先都道府県、設置先市区、
 *                                        設置先住所１、設置先住所２、設置先電話番号、設置先担当者名が入力されている場合
 *                                        書式等のチェックを行うよう処理を追加。
 *                                        発注可能チェックの追加。
 *  2010-01-25    1.26  K.Hosoi          【E_本稼動_00533,00319】作業依頼中フラグをYにする際、合わせて購買依頼番号/顧客CD
 *                                        をATTRIBUTE8に設定する処理を追加。また、顧客の業態小分類が24～27以外且つ、顧客の
 *                                        顧客区分が10で且つ、機種の機器区分が自販機の場合には購買依頼が実施できないように
 *                                        修正。
 *  2010-03-08    1.27  K.Hosoi          【E_本稼動_01838,01839】
 *                                        ・作業依頼中フラグが「Y」の依頼が、「差戻」「取消」の場合は申請可能となるよう修正
 *                                        ・新台代替／旧台代替／引揚の場合に、引揚先（搬入先）妥当性チェックを追加
 *                                        ・作業会社CD妥当性チェックを追加
 *                                        ・作業希望日妥当性チェックを追加。
 *  2010-04-01    1.28  T.maruyama       【E_本稼動_02133】
 *                                        ・業態小分類と機種のチェックの際、旧台作業の場合はiProで機種CDを入力しないため
 *                                          設置物件CDからIBの機種CDを取得して使用するよう変更。
 *                                        ・作業希望日チェックの際に、チェックしている日付を出力するようログ追加。
 *  2010-04-19    1.29  T.Maruyama       【E_本稼動_02251】作業希望日チェックで使用するカレンダをプロファイル管理する用変更。
 *  2010-07-29    1.30  M.Watanabe       【E_本稼動_03239】
 *                                        ・VD購買依頼時の3営業日ルールを新台設置／新台代替の場合にチェックするよう条件追加。
 *                                          (入力チェック区分=07 作業関連情報入力チェック)
 *                                        ・引揚の場合にチェックしているVD購買依頼時の3営業日ルールをコメントアウト。
 *                                          (入力チェック区分=10 引揚関連情報入力チェック2)
 *  2010-12-07    1.31 K.Kiriu           【E_本稼動_05751】
 *                                        ・廃棄決裁時の機器状態３のチェックを「NULL、予定無し、廃棄予定以外の場合エラー」に変更
 *  2013-04-04    1.32 T.Ishiwata        【E_本稼動_10321】
 *                                        ・新台設置、新台代替のときにAPPS_SOURCE_CODEがNULLかどうかチェックするように変更
 *  2013-12-05    1.33 T.Nakano          【E_本稼動_11082】
 *                                        ・自販機、ショーケース廃棄決済申請チェックを追加
 *  2014-04-30    1.34 T.Nakano          【E_本稼動_11770】
 *                                        ・自販機、ショーケース廃棄決済申請チェックの条件変更
 *  2014-05-13    1.35 K.Nakamura        【E_本稼動_11853】ベンダー購入対応
 *  2014-08-29    1.36 S.Yamashita       【E_本稼動_11719】ベンダー購入対応(PH2)
 *  2014-12-15    1.37 K.Kanada          【E_本稼動_12775】廃棄決裁の条件変更
 *  2015-01-13    1.38 T.Sano            【E_本稼動_12289】対応売上・担当拠点妥当性チェックを追加 
 *
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;          -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;          -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id;  -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                     -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  固定部 END   ##################################
  --
  --#######################  固定グローバル変数宣言部 START   #######################
  --
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
  gv_requisition_number po_requisition_headers.segment1%type;
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER; -- 対象件数
  gn_normal_cnt    NUMBER; -- 正常件数
  gn_error_cnt     NUMBER; -- エラー件数
  gn_warn_cnt      NUMBER; -- スキップ件数
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCSO011A01C';  -- パッケージ名
  cv_sales_appl_short_name     CONSTANT VARCHAR2(5)   := 'XXCSO';         -- 営業用アプリケーション短縮名
  cv_com_appl_short_name       CONSTANT VARCHAR2(5)   := 'XXCCP';         -- 共通用アプリケーション短縮名
  --
  -- 処理結果
  cv_result_yes    CONSTANT VARCHAR2(1) := 'Y';
  cv_result_no     CONSTANT VARCHAR2(1) := 'N';
  --
  -- メッセージコード
  cv_tkn_number_01  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00469';  -- パラメータ必須チェックエラー
  cv_tkn_number_02  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00524';  -- ワークフロー情報取得エラー
  cv_tkn_number_03  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_04  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00342';  -- 取引タイプIDなしエラー
  cv_tkn_number_05  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00343';  -- 取引タイプID抽出エラー
  cv_tkn_number_06  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- 追加属性ID抽出エラー
  cv_tkn_number_07  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00517';  -- 処理対象データなしエラー
  cv_tkn_number_08  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00344';  -- 発注依頼情報なしエラー
  cv_tkn_number_09  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00345';  -- 必須入力チェックエラー
  cv_tkn_number_10  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00346';  -- 入力チェックエラー
  cv_tkn_number_11  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00347';  -- 作業希望時間必須入力チェックエラー
  cv_tkn_number_12  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00348';  -- 設置場所階数必須入力チェックエラー
  cv_tkn_number_13  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00349';  -- エレベータ間口、奥行き必須入力チェックエラー
  cv_tkn_number_14  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00350';  -- 延長コード(m)入力チェックエラー
  cv_tkn_number_15  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00351';  -- 物件マスタ存在チェックエラー
  cv_tkn_number_16  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00352';  -- 物件マスタ抽出エラー
  cv_tkn_number_17  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00476';  -- 作業依頼中フラグ_設置用チェックエラー
  cv_tkn_number_18  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00354';  -- 機器状態１（稼動状態）_設置用チェックエラー
  cv_tkn_number_19  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00355';  -- 機器状態３（廃棄情報）_設置用チェックエラー
  cv_tkn_number_20  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00477';  -- 作業依頼中フラグ_引揚用チェックエラー
  cv_tkn_number_21  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00357';  -- 機器状態１（稼動状態）_引揚用チェックエラー
  cv_tkn_number_22  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00478';  -- 作業依頼中フラグ_廃棄用チェックエラー
  cv_tkn_number_23  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00359';  -- 機器状態１（稼動状態）_廃棄用チェックエラー
  cv_tkn_number_24  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00360';  -- 機器状態３（廃棄情報）_廃棄申請用チェックエラー
  cv_tkn_number_25  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00361';  -- 機器状態３（廃棄情報）_廃棄決裁用チェックエラー
  cv_tkn_number_26  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00362';  -- リース物件なしエラー
  cv_tkn_number_27  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00363';  -- リース物件ステータスチェック（設置用）エラー
  cv_tkn_number_28  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00364';  -- リース物件抽出エラー
  cv_tkn_number_29  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00365';  -- リース物件ステータスチェック（廃棄用）エラー
  cv_tkn_number_30  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00366';  -- 所属マスタ存在チェックエラー
  cv_tkn_number_31  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00367';  -- 所属マスタ抽出エラー
  cv_tkn_number_32  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00368';  -- 顧客マスタ存在チェックエラー
  cv_tkn_number_33  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00369';  -- 顧客マスタ抽出エラー
  cv_tkn_number_34  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00370';  -- 顧客ステータスチェックエラー
  cv_tkn_number_35  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00371';  -- 設置用物件情報ロックエラー
  cv_tkn_number_36  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00372';  -- 設置用物件情報抽出エラー
  cv_tkn_number_37  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00373';  -- 設置用物件情報更新エラー
  cv_tkn_number_38  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00374';  -- 引揚用物件情報ロックエラー
  cv_tkn_number_39  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00375';  -- 引揚用物件情報抽出エラー
  cv_tkn_number_40  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00376';  -- 引揚用物件情報更新エラー
  cv_tkn_number_41  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00377';  -- 廃棄用物件情報ロックエラー
  cv_tkn_number_42  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00378';  -- 廃棄用物件情報抽出エラー
  cv_tkn_number_43  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00379';  -- 追加属性値ID抽出エラー
  cv_tkn_number_44  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00380';  -- 廃棄用物件情報更新エラー
  cv_tkn_number_45  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00516';  -- 作業依頼／発注情報連携対象テーブル登録エラー
/*20090413_yabuki_ST170 START*/
  cv_tkn_number_46  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00561';  -- 作業希望日入力チェックエラーメッセージ
/*20090413_yabuki_ST170 END*/
/*20090413_yabuki_ST171 START*/
  cv_tkn_number_47  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00562';  -- 設置場所階数入力チェックエラーメッセージ
/*20090413_yabuki_ST171 END*/
/*20090416_yabuki_ST549 START*/
  cv_tkn_number_48  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00563';  -- ステータスID取得エラー
  cv_tkn_number_49  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00564';  -- ステータスID抽出エラー
/*20090416_yabuki_ST549 END*/
/*20090427_yabuki_ST505_517 START*/
  cv_tkn_number_50  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00566';  -- 設置物件・顧客関連性チェックエラー
  cv_tkn_number_51  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00567';  -- 引揚物件・顧客関連性チェックエラー
/*20090427_yabuki_ST505_517 END*/
/* 20090511_abe_ST965 START*/
  cv_tkn_number_52  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00193';  -- 物件ワークテーブルの機器状態不正
/* 20090511_abe_ST965 END*/
/* 20090701_abe_ST529 START*/
  cv_tkn_number_53  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00576';  -- 発注依頼明細更新エラー
/* 20090701_abe_ST529 END*/
/* 20090708_abe_0000464 START*/
  cv_tkn_number_54  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00577';  -- メーカーコード存在チェックエラー
/* 20090708_abe_0000464 END*/
  /* 2009.09.10 K.Satomura 0001335対応 START */
  cv_tkn_number_55  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00579';  -- 顧客ステータスチェックエラーメッセージ
  /* 2009.09.10 K.Satomura 0001335対応 END */
  /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
  cv_tkn_number_56  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00582';  -- 作業希望日妥当性チェックエラーメッセージ
  cv_tkn_number_57  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00583';  -- 書式チェックエラーメッセージ
  cv_tkn_number_58  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00584';  -- 作業会社メーカーチェックエラーメッセージ
  cv_tkn_number_59  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00585';  -- 引揚先入力不可チェックエラーメッセージ
  /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
  cv_tkn_number_60  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00588';  -- 物件未依頼エラーメッセージ
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
  /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
  cv_tkn_number_61  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- データ抽出エラーメッセージ
  cv_tkn_number_62  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00592';  -- 業態(小分類)チェックエラーメッセージ
  /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
  /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
  cv_tkn_number_63  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00598';  -- 引揚先(搬入先)妥当性チェックエラーメッセージ
  cv_tkn_number_64  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00599';  -- 作業会社妥当性チェックエラーメッセージ
  cv_tkn_number_65  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00600';  -- 作業希望日妥当性チェックエラーメッセージ
  /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
  /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 START */
  cv_tkn_number_66  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00647';  -- アプリケーションソースコードチェックエラーメッセージ
  /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 END   */
  /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
  cv_tkn_number_67  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00657';  -- 廃棄決済申請チェックエラー
  cv_tkn_number_68  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00658';  -- 償却チェックデータ抽出エラー
  cv_tkn_number_69  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00659';  -- メッセージ用文字列(リース契約情報)
  cv_tkn_number_70  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00660';  -- メッセージ用文字列(償却日)
  /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
  /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
  cv_tkn_number_71  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_72  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- 存在エラー
  cv_tkn_number_73  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00055';  -- データ抽出エラー
  cv_tkn_number_74  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- メッセージ用文字列(申告地)
  cv_tkn_number_75  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00663';  -- メッセージ用文字列(申告地マスタ)
  cv_tkn_number_76  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00545';  -- 参照タイプ内容取得エラーメッセージ
  /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
  /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
  cv_tkn_number_77  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00717';  -- 参照タイプ内容取得エラーメッセージ
  /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
  --
  -- トークンコード
  cv_tkn_param_nm       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_item           CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_value          CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_task_nm        CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_src_tran_type  CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  cv_tkn_err_msg        CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_add_attr_nm    CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_add_attr_cd    CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_bukken         CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_status1        CONSTANT VARCHAR2(20) := 'STATUS1';
  cv_tkn_status3        CONSTANT VARCHAR2(20) := 'STATUS3';
  cv_tkn_wk_company_cd  CONSTANT VARCHAR2(20) := 'WORK_COMPANY_CODE';
  cv_tkn_location_cd    CONSTANT VARCHAR2(20) := 'LOCATION_CODE';
  cv_tkn_kokyaku        CONSTANT VARCHAR2(20) := 'KOKYAKU';
  cv_tkn_cust_status    CONSTANT VARCHAR2(20) := 'CUST_STATUS';
  cv_tkn_api_err_msg    CONSTANT VARCHAR2(20) := 'API_ERR_MSG';
  cv_tkn_req_num        CONSTANT VARCHAR2(20) := 'REQUISITION_NUM';
  cv_tkn_req_line_num   CONSTANT VARCHAR2(20) := 'REQUISITION_LINE_NUM';
/*20090406_yabuki_ST297 START*/
  cv_tkn_req_header_num CONSTANT VARCHAR2(20) := 'REQ_HEADER_NUM';
/*20090406_yabuki_ST297 END*/
/*20090406_yabuki_ST101 START*/
  cv_tkn_process        CONSTANT VARCHAR2(20) := 'PROCESS';
/*20090406_yabuki_ST101 END*/
/*20090413_yabuki_ST170 START*/
  cv_tkn_req_date       CONSTANT VARCHAR2(20) := 'REQUEST_DATE';
/*20090413_yabuki_ST170 END*/
/* 20090511_abe_ST965 START*/
  cv_tkn_hazard_state1    CONSTANT VARCHAR2(20) := 'HAZARD_STATE1';
  cv_tkn_hazard_state2    CONSTANT VARCHAR2(20) := 'HAZARD_STATE2';
  cv_tkn_hazard_state3    CONSTANT VARCHAR2(20) := 'HAZARD_STATE3';
  /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
  cv_tkn_colname        CONSTANT VARCHAR2(20) := 'COLNAME';
  cv_tkn_format         CONSTANT VARCHAR2(20) := 'FORMAT';
  /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */  
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
  cv_tkn_sagyo          CONSTANT VARCHAR(20)  := 'SAGYO';
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
  /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
  cv_tkn_base_val       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_kisyucd        CONSTANT VARCHAR2(20) := 'KISYUCD';
  /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
  /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
  cv_tkn_prefix         CONSTANT VARCHAR2(20) := 'PREFIX';
  cv_tkn_prefix1        CONSTANT VARCHAR2(20) := 'PREFIX1';
  cv_tkn_prefix2        CONSTANT VARCHAR2(20) := 'PREFIX2';
  cv_tkn_date           CONSTANT VARCHAR2(20) := 'DATE';
  /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
  /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_prof_name        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
  --
  cv_machinery_status       CONSTANT VARCHAR2(100) := '物件データワークテーブルの機器状態';
/* 20090511_abe_ST965 END*/
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
  cv_tkn_install            CONSTANT VARCHAR(20)  := '設置';
  cv_tkn_withdraw           CONSTANT VARCHAR(20)  := '引揚';
  cv_tkn_ablsh              CONSTANT VARCHAR(20)  := '廃棄';
  cv_tkn_subject1           CONSTANT VARCHAR(20)  := '購買依頼 ';
  cv_tkn_subject2           CONSTANT VARCHAR(100) := ' 申請時のチェック処理でエラーが発生しました';
  cv_tkn_subject3           CONSTANT VARCHAR(100) := ' 承認時のチェック処理でエラーが発生しました';
  /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
  --
/*20090416_yabuki_ST549 START*/
  -- 参照タイプのIBステータスタイプコード
  cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
/*20090416_yabuki_ST549 END*/
  --
  -- 複数エラーメッセージの区切り文字（カンマ）
  cv_msg_comma CONSTANT VARCHAR2(3) := ' , ';
  --
  -- 区切り文字
  cv_msg_part_only  CONSTANT VARCHAR2(1) := ':';
  --
  /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
  -- 区切り記号
  cv_slash          CONSTANT VARCHAR2(1) := '/';
  /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
  -- 処理区分
  cv_proc_kbn_req_appl  CONSTANT VARCHAR2(1) := '1';  -- 発注依頼申請
  cv_proc_kbn_req_aprv  CONSTANT VARCHAR2(1) := '2';  -- 発注依頼承認
/*20090416_yabuki_ST398 START*/
  cv_proc_kbn_req_dngtn CONSTANT VARCHAR2(1) := '3';  -- 発注依頼否認
/*20090416_yabuki_ST398 END*/
  --
  -- カテゴリ区分
  cv_category_kbn_new_install  CONSTANT VARCHAR2(5) := '10';  -- 新台設置
  cv_category_kbn_new_replace  CONSTANT VARCHAR2(5) := '20';  -- 新台代替
  cv_category_kbn_old_install  CONSTANT VARCHAR2(5) := '30';  -- 旧台設置
  cv_category_kbn_old_replace  CONSTANT VARCHAR2(5) := '40';  -- 旧台代替
  cv_category_kbn_withdraw     CONSTANT VARCHAR2(5) := '50';  -- 引揚
  cv_category_kbn_ablsh_appl   CONSTANT VARCHAR2(5) := '60';  -- 廃棄申請
  cv_category_kbn_ablsh_dcsn   CONSTANT VARCHAR2(5) := '70';  -- 廃棄決裁
  cv_category_kbn_mvmt_in_shp  CONSTANT VARCHAR2(5) := '80';  -- 店内移動
  --
  -- 追加属性コード
  cv_attr_cd_jotai_kbn3      CONSTANT VARCHAR2(30) := 'JOTAI_KBN3';      -- 機器状態３（廃棄情報）
  cv_attr_cd_haikikessai_dt  CONSTANT VARCHAR2(30) := 'HAIKIKESSAI_DT';  -- 廃棄決裁日
  cv_attr_cd_ven_haiki_flg   CONSTANT VARCHAR2(30) := 'VEN_HAIKI_FLG';   -- 廃棄フラグ
  -- 追加属性名
  cv_attr_nm_jotai_kbn3      CONSTANT VARCHAR2(30) := '機器状態３（廃棄情報）';
  cv_attr_nm_haikikessai_dt  CONSTANT VARCHAR2(30) := '廃棄決裁日';
  cv_attr_nm_ven_haiki_flg   CONSTANT VARCHAR2(30) := '廃棄フラグ';
  --
  -- 入力チェック処理内のチェック区分番号
  cv_input_chk_kbn_01  CONSTANT VARCHAR2(2) := '01';  -- 機種コード必須入力チェック
  cv_input_chk_kbn_02  CONSTANT VARCHAR2(2) := '02';  -- 設置用物件コード必須入力チェック
  cv_input_chk_kbn_03  CONSTANT VARCHAR2(2) := '03';  -- 設置用物件コード入力チェック
  cv_input_chk_kbn_04  CONSTANT VARCHAR2(2) := '04';  -- 引揚用物件コード入力チェック
  cv_input_chk_kbn_05  CONSTANT VARCHAR2(2) := '05';  -- 引揚用物件コード必須入力チェック
  cv_input_chk_kbn_06  CONSTANT VARCHAR2(2) := '06';  -- 設置先_顧客コード必須入力チェック
  cv_input_chk_kbn_07  CONSTANT VARCHAR2(2) := '07';  -- 作業関連情報入力チェック
  cv_input_chk_kbn_08  CONSTANT VARCHAR2(2) := '08';  -- 引揚関連情報入力チェック
  cv_input_chk_kbn_09  CONSTANT VARCHAR2(2) := '09';  -- 廃棄_物件コード必須入力チェック
/*20090413_yabuki_ST170_ST171 START*/
  cv_input_chk_kbn_10  CONSTANT VARCHAR2(2) := '10';  -- 引揚関連情報入力チェック２
/*20090413_yabuki_ST170_ST171 END*/
/* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
  cv_input_chk_kbn_11  CONSTANT VARCHAR2(2) := '11';  -- 作業会社メーカーチェック
  cv_input_chk_kbn_12  CONSTANT VARCHAR2(2) := '12';  -- 引揚先入力不可チェック
/* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
/* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
  cv_input_chk_kbn_13  CONSTANT VARCHAR2(2) := '13';  -- 顧客関連情報入力チェック
/* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
/* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
  cv_input_chk_kbn_14  CONSTANT VARCHAR2(2) := '14';  -- 引揚先(搬入先)妥当性チェック
  cv_input_chk_kbn_15  CONSTANT VARCHAR2(2) := '15';  -- 作業会社妥当性チェック
/* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
  cv_input_chk_kbn_16  CONSTANT VARCHAR2(2) := '16';  -- 申告地必須入力チェック
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
/* 2015-01-13 T.Sano E_本稼動_12289対応 START */
  cv_input_chk_kbn_17  CONSTANT VARCHAR2(2) := '17';  -- 売上・担当拠点妥当性チェック
/* 2015-01-13 T.Sano E_本稼動_12289対応 END */
  --
  -- 物件ステータスチェック処理内のチェック区分番号
  cv_obj_sts_chk_kbn_01  CONSTANT VARCHAR2(2) := '01';  -- チェック対象：設置用物件
  cv_obj_sts_chk_kbn_02  CONSTANT VARCHAR2(2) := '02';  -- チェック対象：廃棄用物件
  --
  -- 物件関連の項目の固定値
  cv_op_req_flag_on         CONSTANT VARCHAR2(1) := 'Y';  -- 作業依頼中フラグ「ＯＮ」
/*20090416_yabuki_ST398 START*/
  cv_op_req_flag_off        CONSTANT VARCHAR2(1) := 'N';  -- 作業依頼中フラグ「ＯＦＦ」
/*20090416_yabuki_ST398 END*/
  cv_jotai_kbn1_operate     CONSTANT VARCHAR2(1) := '1';  -- 機器状態１（稼動状態）「稼動」
  cv_jotai_kbn1_hold        CONSTANT VARCHAR2(1) := '2';  -- 機器状態１（稼動状態）「滞留」
  cv_jotai_kbn3_non_schdl   CONSTANT VARCHAR2(1) := '0';  -- 機器状態３（廃棄情報）「予定無」
  /* 2009.11.25 K.Satomura E_本稼動_00027対応 START */
  cv_jotai_kbn3_ablsh_pln   CONSTANT VARCHAR2(1) := '1';  -- 機器状態３（廃棄情報）「廃棄予定」
  /* 2009.11.25 K.Satomura E_本稼動_00027対応 END */
  cv_jotai_kbn3_ablsh_appl  CONSTANT VARCHAR2(1) := '2';  -- 機器状態３（廃棄情報）「廃棄申請中」

  
/* 20090511_abe_ST965 START*/
  cn_num0                  CONSTANT NUMBER        := 0;
  cn_num1                  CONSTANT NUMBER        := 1;
  cn_num2                  CONSTANT NUMBER        := 2;
  cn_num3                  CONSTANT NUMBER        := 3;
  cn_num4                  CONSTANT NUMBER        := 4;
  cn_num9                  CONSTANT NUMBER        := 9;
/* 20090511_abe_ST965 END*/
/* 20090515_abe_ST669 START*/
  cv_VerifyAuthority_y        CONSTANT VARCHAR2(1) := 'Y';  -- 承認権限チェックフラグ(OK)
/* 20090515_abe_ST669 END*/

/*20090403_yabuki_ST297 START*/
  -- 固定の数値
  cn_zero    CONSTANT NUMBER := 0;
  cn_one     CONSTANT NUMBER := 1;
/*20090403_yabuki_ST297 END*/
/*20090406_yabuki_ST101 START*/
  cv_interface_flg_off      CONSTANT VARCHAR2(1) := 'N';  -- 連携済フラグ「ＯＦＦ」
/*20090406_yabuki_ST101 END*/
/*20090413_yabuki_ST198 START*/
  cv_own_company_lease      CONSTANT VARCHAR2(1) := '1';  -- リース区分「自社リース」
/*20090413_yabuki_ST198 END*/
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
  cv_fixed_assets           CONSTANT VARCHAR2(1) := '4';  -- リース区分「固定資産」
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
/* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
  cb_true                   CONSTANT BOOLEAN     := TRUE;
  cb_false                  CONSTANT BOOLEAN     := FALSE;
/* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
/*20090413_yabuki_ST549 START*/
  gt_instance_status_id_1 csi_instance_statuses.instance_status_id%TYPE; -- 稼働中
  gt_instance_status_id_2 csi_instance_statuses.instance_status_id%TYPE; -- 使用可
  gt_instance_status_id_3 csi_instance_statuses.instance_status_id%TYPE; -- 整備中
  gt_instance_status_id_4 csi_instance_statuses.instance_status_id%TYPE; -- 廃棄手続中
  gt_instance_status_id_5 csi_instance_statuses.instance_status_id%TYPE; -- 廃棄処理済
  gt_instance_status_id_6 csi_instance_statuses.instance_status_id%TYPE; -- 物件削除済
/*20090413_yabuki_ST549 END*/
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- IB追加属性ID
  TYPE g_ib_ext_attr_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- 機器状態3
    , abolishment_decision_date  NUMBER  -- 廃棄決裁日
    , abolishment_flag           NUMBER  -- 廃棄フラグ
  );
  --
  -- IB追加属性値ID
  TYPE g_ib_ext_attr_val_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- 機器状態3
    , abolishment_decision_date  NUMBER  -- 廃棄決裁日
    , abolishment_flag           NUMBER  -- 廃棄フラグ
  );
  --
  -- 発注依頼情報
  TYPE g_requisition_rtype IS RECORD(
      requisition_header_id     xxcso_requisition_lines_v.requisition_header_id%TYPE     -- 発注依頼ヘッダID
    , requisition_line_id       xxcso_requisition_lines_v.requisition_line_id%TYPE       -- 発注依頼明細ID
    , requisition_number        po_requisition_headers.segment1%TYPE                     -- 発注依頼番号
    , requisition_line_number   xxcso_requisition_lines_v.line_num%TYPE                  -- 発注依頼明細番号
    , category_kbn              xxcso_requisition_lines_v.category_kbn%TYPE              -- カテゴリ区分
    , un_number                 po_un_numbers_vl.un_number%TYPE                          -- 機種コード
    , install_code              xxcso_requisition_lines_v.install_code%TYPE              -- 設置用物件コード
    , withdraw_install_code     xxcso_requisition_lines_v.withdraw_install_code%TYPE     -- 引揚用物件コード
    , install_at_customer_code  xxcso_requisition_lines_v.install_at_customer_code%TYPE  -- 設置先_顧客コード
    , work_hope_time_type       xxcso_requisition_lines_v.work_hope_time_type%TYPE       -- 作業希望時間区分
    , work_hope_time_hour       xxcso_requisition_lines_v.work_hope_time_hour%TYPE       -- 作業希望時
    , work_hope_time_minute     xxcso_requisition_lines_v.work_hope_time_minute%TYPE     -- 作業希望分
    /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
    , sold_charge_base          xxcso_requisition_lines_v.sold_charge_base%TYPE     -- 売上・担当拠点
    /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
    , install_place_type        xxcso_requisition_lines_v.install_place_type%TYPE        -- 設置場所区分
    , install_place_floor       xxcso_requisition_lines_v.install_place_floor%TYPE       -- 設置場所階数
    , elevator_frontage         xxcso_requisition_lines_v.elevator_frontage%TYPE         -- エレベータ間口
    , elevator_depth            xxcso_requisition_lines_v.elevator_depth%TYPE            -- エレベータ奥行き
    , extension_code_type       xxcso_requisition_lines_v.extension_code_type%TYPE       -- 延長コード区分
    , extension_code_meter      xxcso_requisition_lines_v.extension_code_meter%TYPE      -- 延長コード（ｍ）
    , abolishment_install_code  xxcso_requisition_lines_v.abolishment_install_code%TYPE  -- 廃棄_物件コード
    , work_company_code         xxcso_requisition_lines_v.work_company_code%TYPE         -- 作業会社コード
    , work_location_code        xxcso_requisition_lines_v.work_location_code%TYPE        -- 事業所コード
    , withdraw_company_code     xxcso_requisition_lines_v.withdraw_company_code%TYPE     -- 引揚会社コード
    , withdraw_location_code    xxcso_requisition_lines_v.withdraw_location_code%TYPE    -- 引揚事業所コード
/*20090413_yabuki_ST170 START*/
    , work_hope_year            xxcso_requisition_lines_v.work_hope_year%TYPE            -- 作業希望年
    , work_hope_month           xxcso_requisition_lines_v.work_hope_month%TYPE           -- 作業希望月
    , work_hope_day             xxcso_requisition_lines_v.work_hope_day%TYPE             -- 作業希望日
    , request_date              xxcso_requisition_lines_v.creation_date%TYPE             -- 依頼日
/*20090413_yabuki_ST170 END*/
/*20090427_yabuki_ST505_517 START*/
    , created_by                po_requisition_headers.created_by%TYPE                   -- 作成日
/*20090427_yabuki_ST505_517 END*/
/* 20090708_abe_0000464 START*/
    , category_id               xxcso_requisition_lines_v.category_id%TYPE              -- カテゴリID
    , maker_code                po_un_numbers_vl.attribute2%TYPE                        -- メーカコード
/* 20090708_abe_0000464 END*/
/* 2013.04.04 T.Ishiwata E_本稼動_10321対応 START */
    , apps_source_code          po_requisition_headers.apps_source_code%TYPE            -- アプリケーションソースコード
/* 2013.04.04 T.Ishiwata E_本稼動_10321対応 END   */
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    , declaration_place         xxcso_requisition_lines_v.declaration_place%TYPE        -- 申告地
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
  );
  --
  -- 物件情報
  TYPE g_instance_rtype IS RECORD(
      instance_id  xxcso_install_base_v.instance_id%TYPE            -- インスタンスID
    , op_req_flag  xxcso_install_base_v.op_request_flag%TYPE        -- 作業依頼中フラグ
    , jotai_kbn1   xxcso_install_base_v.jotai_kbn1%TYPE             -- 機器状態１（稼動状態）
    , jotai_kbn3   xxcso_install_base_v.jotai_kbn3%TYPE             -- 機器状態３（廃棄情報）
    , obj_ver_num  xxcso_install_base_v.object_version_number%TYPE  -- オブジェクトバージョン番号
/*20090413_yabuki_ST198 START*/
    , lease_kbn    xxcso_install_base_v.lease_kbn%TYPE              -- リース区分
/*20090413_yabuki_ST198 END*/
/*20090427_yabuki_ST505_517 START*/
    , owner_account_id  xxcso_install_base_v.install_account_id%TYPE  -- 設置先アカウントID
/*20090427_yabuki_ST505_517 END*/
/* 20090511_abe_ST965 START*/
    ,jotai_kbn2    xxcso_install_base_v.jotai_kbn2%TYPE             -- 機器状態２（状態詳細）
    ,delete_flag   xxcso_install_base_v.sakujo_flg%TYPE             -- 削除フラグ
    ,install_code  xxcso_install_base_v.install_code%TYPE           -- 物件コード
/* 20090511_abe_ST965 END*/
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
    ,op_req_number_account_number xxcso_install_base_v.op_req_number_account_number%TYPE  -- 作業依頼中購買依頼番号/顧客CD
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    ,instance_type_code           xxcso_install_base_v.instance_type_code%TYPE            -- インスタンスタイプコード
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
  );
  --
  -- ===============================
  -- ユーザー定義グローバル例外
  -- ===============================
  g_lock_expt         EXCEPTION;  -- ロック例外
  --
  PRAGMA EXCEPTION_INIT( g_lock_expt, -54 );
  --
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_itemtype             IN         VARCHAR2
    , iv_itemkey              IN         VARCHAR2
    , iv_process_kbn          IN         VARCHAR2                                -- 処理区分
    , ov_requisition_number   OUT NOCOPY po_requisition_headers.segment1%TYPE    -- 発注依頼番号
    , od_process_date         OUT NOCOPY DATE                                    -- 業務処理日付
    , on_transaction_type_id  OUT NOCOPY csi_txn_types.transaction_type_id%TYPE  -- 取引タイプID
    , o_ib_ext_attr_id_rec    OUT NOCOPY g_ib_ext_attr_id_rtype                  -- IB追加属性ID情報
    , ov_errbuf               OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode              OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- プロシージャ名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_itemtype    CONSTANT VARCHAR2(30) := 'ITEMTYPE';
    cv_itemkey     CONSTANT VARCHAR2(30) := 'ITEMKEY';
    cv_doc_number  CONSTANT VARCHAR2(30) := 'DOCUMENT_NUMBER';
    cv_ib_ui       CONSTANT VARCHAR2(30) := 'IB_UI';
    --
    -- トークン用
    cv_tkn_val_req_number     CONSTANT VARCHAR2(30)  := '発注依頼番号';
    cv_tkn_val_process_kbn    CONSTANT VARCHAR2(30)  := '処理区分';
    cv_tkn_val_tran_type_id   CONSTANT VARCHAR2(30)  := '取引タイプの取引タイプＩＤ';
    cv_tkn_val_ext_attr_id    CONSTANT VARCHAR2(30)  := '追加属性ＩＤ';
/*20090416_yabuki_ST549 START*/
    cv_tkn_val_status_nm      CONSTANT VARCHAR2(30)  := 'ステータス名';
/*20090416_yabuki_ST549 END*/
    --
/*20090416_yabuki_ST549 START*/
    -- 参照タイプのIBステータスコード
    cv_instance_status_1      CONSTANT VARCHAR2(1)   := '1';    -- 稼動中
    cv_instance_status_2      CONSTANT VARCHAR2(1)   := '2';    -- 使用可
    cv_instance_status_3      CONSTANT VARCHAR2(1)   := '3';    -- 整備中
    cv_instance_status_4      CONSTANT VARCHAR2(1)   := '4';    -- 廃棄手続中
    cv_instance_status_5      CONSTANT VARCHAR2(1)   := '5';    -- 廃棄処理済
    cv_instance_status_6      CONSTANT VARCHAR2(1)   := '6';    -- 物件削除済
    --
    -- インスタンスステータス名
    cv_status_name01          CONSTANT VARCHAR2(100) := '稼働中';
    cv_status_name02          CONSTANT VARCHAR2(100) := '使用可';
    cv_status_name03          CONSTANT VARCHAR2(100) := '整備中';
    cv_status_name04          CONSTANT VARCHAR2(100) := '廃棄手続中';
    cv_status_name05          CONSTANT VARCHAR2(100) := '廃棄処理済';
    cv_status_name06          CONSTANT VARCHAR2(100) := '物件削除済';
    --
    -- 抽出内容名
    cv_instance_status        CONSTANT VARCHAR2(100) := '物件のステータスID';
/*20090416_yabuki_ST549 END*/
    --
    -- *** ローカル変数 ***
/*20090416_yabuki_ST549 START*/
    lt_status_name    csi_instance_statuses.name%TYPE;
/*20090416_yabuki_ST549 END*/
    --
    -- *** ローカル例外 ***
    input_parameter_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ======================
    -- 入力パラメータチェック
    -- ======================
    -- ワークフローのITEMTYPE
    IF ( iv_itemtype IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_01          -- メッセージコード
                     , iv_token_name1  => cv_tkn_param_nm           -- トークコード1
                     , iv_token_value1 => cv_itemtype               -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ワークフローのITEMKEY
    IF ( iv_itemkey IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_01          -- メッセージコード
                     , iv_token_name1  => cv_tkn_param_nm           -- トークコード1
                     , iv_token_value1 => cv_itemkey                -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ======================
    -- 発注依頼番号取得
    -- ======================
    ov_requisition_number := po_wf_util_pkg.getitemattrtext(
                                 itemtype => iv_itemtype
                               , itemkey  => iv_itemkey
                               , aname    => cv_doc_number
                             );
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    gv_requisition_number := ov_requisition_number;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    -- 発注依頼番号が取得できなかった場合エラー
    IF ( ov_requisition_number IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_02          -- メッセージコード
                     , iv_token_name1  => cv_tkn_param_nm           -- トークコード1
                     , iv_token_value1 => cv_tkn_val_req_number     -- トークン値1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ======================
    -- 業務処理日付取得
    -- ======================
    od_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( od_process_date IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_03          -- メッセージコード
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ======================
    -- 取引タイプID抽出
    -- ======================
    BEGIN
      SELECT transaction_type_id
      INTO   on_transaction_type_id
      FROM   csi_txn_types
      WHERE  source_transaction_type = cv_ib_ui
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 該当データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_04           -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm             -- トークコード1
                       , iv_token_value1 => cv_tkn_val_tran_type_id    -- トークン値1
                       , iv_token_name2  => cv_tkn_src_tran_type       -- トークコード2
                       , iv_token_value2 => cv_ib_ui                   -- トークン値2
                     );
        --
        RAISE input_parameter_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_05           -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm             -- トークコード1
                       , iv_token_value1 => cv_tkn_val_tran_type_id    -- トークン値1
                       , iv_token_name2  => cv_tkn_src_tran_type       -- トークコード2
                       , iv_token_value2 => cv_ib_ui                   -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg             -- トークコード3
                       , iv_token_value3 => SQLERRM                    -- トークン値3
                     );
        --
        RAISE input_parameter_expt;
        --
    END;
    --
    -- ======================
    -- IB追加属性ID取得
    -- ======================
    -- 機器状態３（廃棄情報）
    o_ib_ext_attr_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           iv_attribute_code => cv_attr_cd_jotai_kbn3
                                         , id_standard_date  => od_process_date
                                       );
    --
    -- 機器状態３（廃棄情報）の追加属性IDが取得できなかった場合エラー
    IF ( o_ib_ext_attr_id_rec.jotai_kbn3 IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_06          -- メッセージコード
                     , iv_token_name1  => cv_tkn_task_nm            -- トークコード1
                     , iv_token_value1 => cv_tkn_val_ext_attr_id    -- トークン値1
                     , iv_token_name2  => cv_tkn_add_attr_nm        -- トークコード2
                     , iv_token_value2 => cv_attr_nm_jotai_kbn3     -- トークン値2
                     , iv_token_name3  => cv_tkn_add_attr_cd        -- トークコード3
                     , iv_token_value3 => cv_attr_cd_jotai_kbn3     -- トークン値3
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- 廃棄決裁日
    o_ib_ext_attr_id_rec.abolishment_decision_date := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                          iv_attribute_code => cv_attr_cd_haikikessai_dt
                                                        , id_standard_date  => od_process_date
                                                      );
    --
    -- 廃棄決裁日の追加属性IDが取得できなかった場合エラー
    IF ( o_ib_ext_attr_id_rec.abolishment_decision_date IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_06           -- メッセージコード
                     , iv_token_name1  => cv_tkn_task_nm             -- トークコード1
                     , iv_token_value1 => cv_tkn_val_ext_attr_id     -- トークン値1
                     , iv_token_name2  => cv_tkn_add_attr_nm         -- トークコード2
                     , iv_token_value2 => cv_attr_nm_haikikessai_dt  -- トークン値2
                     , iv_token_name3  => cv_tkn_add_attr_cd         -- トークコード3
                     , iv_token_value3 => cv_attr_cd_haikikessai_dt  -- トークン値3
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- 廃棄フラグ
    o_ib_ext_attr_id_rec.abolishment_flag := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                 iv_attribute_code => cv_attr_cd_ven_haiki_flg
                                               , id_standard_date  => od_process_date
                                             );
    --
    -- 廃棄フラグの追加属性IDが取得できなかった場合エラー
    IF ( o_ib_ext_attr_id_rec.abolishment_flag IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_06          -- メッセージコード
                     , iv_token_name1  => cv_tkn_task_nm            -- トークコード1
                     , iv_token_value1 => cv_tkn_val_ext_attr_id    -- トークン値1
                     , iv_token_name2  => cv_tkn_add_attr_nm        -- トークコード2
                     , iv_token_value2 => cv_attr_nm_ven_haiki_flg  -- トークン値2
                     , iv_token_name3  => cv_tkn_add_attr_cd        -- トークコード3
                     , iv_token_value3 => cv_attr_cd_ven_haiki_flg  -- トークン値3
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
/*20090416_yabuki_ST549 START*/
    -- ======================
    -- インスタンスステータスID取得
    -- ======================
    -- 初期化
    lt_status_name := NULL;
    --
    -- 「廃棄手続中」
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                            cv_xxcso1_instance_status
                          , cv_instance_status_4
                          , od_process_date
                        );
      SELECT cis.instance_status_id       -- インスタンスステータスID
      INTO   gt_instance_status_id_4
      FROM   csi_instance_statuses cis    -- インスタンスステータスマスタ
      WHERE  cis.name = lt_status_name
      AND    od_process_date
               BETWEEN TRUNC( NVL( cis.start_date_active, od_process_date ) )
               AND     TRUNC( NVL( cis.end_date_active, od_process_date ) )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_48          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name04          -- トークン値3
                     );
        RAISE input_parameter_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_49          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name04          -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg            -- トークンコード4
                       ,iv_token_value4 => SQLERRM                   -- トークン値4
                     );
        RAISE input_parameter_expt;
    END;
    --
/*20090416_yabuki_ST549 END*/
/* 20090511_abe_ST965 START*/
    -- 初期化
    lt_status_name   := '';
    -- 「使用可」
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_2
                          ,od_process_date);
      SELECT cis.instance_status_id                                     -- インスタンスステータスID
      INTO   gt_instance_status_id_2
      FROM   csi_instance_statuses cis                                  -- インスタンスステータスマスタ
      WHERE  cis.name = lt_status_name
        AND  od_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, od_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, od_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_48          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name02          -- トークン値3
                     );
        RAISE input_parameter_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_49          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name02          -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg            -- トークンコード4
                       ,iv_token_value4 => SQLERRM                   -- トークン値4
                     );
        RAISE input_parameter_expt;
    END;
--
    -- 「整備中」
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_3
                          ,od_process_date);
      SELECT cis.instance_status_id                                   -- インスタンスステータスID
      INTO   gt_instance_status_id_3
      FROM   csi_instance_statuses cis                                -- インスタンスステータスマスタ
      WHERE  cis.name = lt_status_name
        AND  od_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, od_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, od_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_48          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name03          -- トークン値3
                     );
        RAISE input_parameter_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_49          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name03          -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg            -- トークンコード4
                       ,iv_token_value4 => SQLERRM                   -- トークン値4
                     );
        RAISE input_parameter_expt;
    END;
--
--
    -- 初期化
    lt_status_name   := '';
    -- 「物件削除済」
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_6
                          ,od_process_date);
      SELECT cis.instance_status_id                                   -- インスタンスステータスID
      INTO   gt_instance_status_id_6
      FROM   csi_instance_statuses cis                                -- インスタンスステータスマスタ
      WHERE  cis.name = lt_status_name
        AND  od_process_date 
               BETWEEN TRUNC(NVL(cis.start_date_active, od_process_date)) 
                 AND TRUNC(NVL(cis.end_date_active, od_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_48          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name06          -- トークン値3
                     );
        RAISE input_parameter_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_49          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       ,iv_token_value1 => cv_instance_status        -- トークン値1
                       ,iv_token_name2  => cv_tkn_item               -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- トークン値2
                       ,iv_token_name3  => cv_tkn_value              -- トークンコード3
                       ,iv_token_value3 => cv_status_name06          -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg            -- トークンコード4
                       ,iv_token_value4 => SQLERRM                   -- トークン値4
                     );
        RAISE input_parameter_expt;
    END;
/* 20090511_abe_ST965 END*/
    --
  EXCEPTION
    --
    WHEN input_parameter_expt THEN
      -- *** 入力パラメータチェックエラー時 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END init;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_requisition_info
   * Description      : 発注依頼情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_requisition_info(
      iv_requisition_number  IN         po_requisition_headers.segment1%TYPE  -- 発注依頼番号
    , id_process_date        IN         DATE                                  -- 業務処理日付
/*20090403_yabuki_ST297 START*/
    , on_rec_count           OUT NOCOPY NUMBER               -- 抽出件数
/*20090403_yabuki_ST297 END*/
    , o_requisition_rec      OUT NOCOPY g_requisition_rtype  -- 発注依頼情報
    , ov_errbuf              OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode             OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_requisition_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_val_requisition  CONSTANT VARCHAR2(100) := '発注依頼';
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル例外 ***
    sql_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
/*20090403_yabuki_ST297 START*/
    -- 処理件数を初期化
    on_rec_count := cn_zero;
/*20090403_yabuki_ST297 END*/
    --
    -- ============================
    -- 発注依頼情報抽出
    -- ============================
    BEGIN
      SELECT xrlv.requisition_header_id     requisition_header_id     -- 発注依頼ヘッダID
           , xrlv.requisition_line_id       requisition_line_id       -- 発注依頼明細ID
           , prh.segment1                   requisition_number        -- 発注依頼番号
           , xrlv.line_num                  requisition_line_number   -- 発注依頼明細番号
           , xrlv.category_kbn              category_kbn              -- カテゴリ区分
           , ( SELECT punv.un_number
               FROM   po_un_numbers_vl  punv
               WHERE  punv.un_number_id = xrlv.un_number_id
           /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
           --    AND    TRUNC( NVL( punv.inactive_date, id_process_date + 1 ) ) 
           --            > TRUNC( id_process_date ) )  un_number    -- 機種コード
              )  un_number    -- 機種コード
           /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
           , xrlv.install_code              install_code              -- 設置用物件コード
           , xrlv.withdraw_install_code     withdraw_install_code     -- 引揚用物件コード
           , xrlv.install_at_customer_code  install_at_customer_code  -- 設置先_顧客コード
           , xrlv.work_hope_time_type       work_hope_time_type       -- 作業希望時間区分
           , xrlv.work_hope_time_hour       work_hope_time_hour       -- 作業希望時
           , xrlv.work_hope_time_minute     work_hope_time_minute     -- 作業希望分
           /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
           , xrlv.sold_charge_base          sold_charge_base          -- 売上・担当拠点
           /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
           , xrlv.install_place_type        install_place_type        -- 設置場所区分
           , xrlv.install_place_floor       install_place_floor       -- 設置場所階数
           , xrlv.elevator_frontage         elevator_frontage         -- エレベータ間口
           , xrlv.elevator_depth            elevator_depth            -- エレベータ奥行き
           , xrlv.extension_code_type       extension_code_type       -- 延長コード区分
           , xrlv.extension_code_meter      extension_code_meter      -- 延長コード（ｍ）
           , xrlv.abolishment_install_code  abolishment_install_code  -- 廃棄_物件コード
           , xrlv.work_company_code         work_company_code         -- 作業会社コード
           , xrlv.work_location_code        work_location_code        -- 事業所コード
           , xrlv.withdraw_company_code     withdraw_company_code     -- 引揚会社コード
           , xrlv.withdraw_location_code    withdraw_location_code    -- 引揚事業所コード
           /*20090413_yabuki_ST170 START*/
           , xrlv.work_hope_year            work_hope_year            -- 作業希望年
           , xrlv.work_hope_month           work_hope_month           -- 作業希望月
           , xrlv.work_hope_day             work_hope_day             -- 作業希望日
           , xrlv.creation_date             request_date              -- 依頼日（作成日）
           /*20090413_yabuki_ST170 END*/
           /*20090427_yabuki_ST505_517 START*/
           , prh.created_by                 created_by                -- 作成者
           /*20090427_yabuki_ST505_517 END*/
/* 20090708_abe_0000464 START*/
           , xrlv.category_id               category_id               -- カテゴリID
           , ( SELECT punv.attribute2
               FROM   po_un_numbers_vl  punv
               WHERE  punv.un_number_id = xrlv.un_number_id
           /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
           --    AND    TRUNC( NVL( punv.inactive_date, id_process_date + 1 ) ) 
           --            > TRUNC( id_process_date ) )  maker_code       -- メーカーコード
              )  maker_code     -- メーカーコード
           /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
/* 20090708_abe_0000464 END*/
           /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 START */
           , prh.apps_source_code           apps_source_code          -- アプリケーションソースコード
           /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 END   */
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
           , xrlv.declaration_place         declaration_place         -- 申告地
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
      INTO   o_requisition_rec.requisition_header_id     -- 発注依頼ヘッダID
           , o_requisition_rec.requisition_line_id       -- 発注依頼明細ID
           , o_requisition_rec.requisition_number        -- 発注依頼番号
           , o_requisition_rec.requisition_line_number   -- 発注依頼明細番号
           , o_requisition_rec.category_kbn              -- カテゴリ区分
           , o_requisition_rec.un_number                 -- 機種コード
           , o_requisition_rec.install_code              -- 設置用物件コード
           , o_requisition_rec.withdraw_install_code     -- 引揚用物件コード
           , o_requisition_rec.install_at_customer_code  -- 設置先_顧客コード
           , o_requisition_rec.work_hope_time_type       -- 作業希望時間区分
           , o_requisition_rec.work_hope_time_hour       -- 作業希望時
           , o_requisition_rec.work_hope_time_minute     -- 作業希望分
           /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
           , o_requisition_rec.sold_charge_base          -- 売上・担当拠点
           /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
           , o_requisition_rec.install_place_type        -- 設置場所区分
           , o_requisition_rec.install_place_floor       -- 設置場所階数
           , o_requisition_rec.elevator_frontage         -- エレベータ間口
           , o_requisition_rec.elevator_depth            -- エレベータ奥行き
           , o_requisition_rec.extension_code_type       -- 延長コード区分
           , o_requisition_rec.extension_code_meter      -- 延長コード（ｍ）
           , o_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
           , o_requisition_rec.work_company_code         -- 作業会社コード
           , o_requisition_rec.work_location_code        -- 事業所コード
           , o_requisition_rec.withdraw_company_code     -- 引揚会社コード
           , o_requisition_rec.withdraw_location_code    -- 引揚事業所コード
           /*20090413_yabuki_ST170 START*/
           , o_requisition_rec.work_hope_year            -- 作業希望年
           , o_requisition_rec.work_hope_month           -- 作業希望月
           , o_requisition_rec.work_hope_day             -- 作業希望日
           , o_requisition_rec.request_date              -- 依頼日
           /*20090413_yabuki_ST170 END*/
           /*20090427_yabuki_ST505_517 START*/
           , o_requisition_rec.created_by                -- 作成者
           /*20090427_yabuki_ST505_517 END*/
/* 20090708_abe_0000464 START*/
           , o_requisition_rec.category_id               -- カテゴリID
           , o_requisition_rec.maker_code                -- メーカーコード
/* 20090708_abe_0000464 END*/
           /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 START */
           , o_requisition_rec.apps_source_code          -- アプリケーションソースコード
           /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 END   */
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
           , o_requisition_rec.declaration_place         -- 申告地
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
      FROM   po_requisition_headers     prh
           , xxcso_requisition_lines_v  xrlv
      WHERE  prh.segment1               = iv_requisition_number
      AND    xrlv.requisition_header_id = prh.requisition_header_id
      /*20090403_yabuki_ST297 START*/
      AND    xrlv.category_kbn IS NOT NULL
      /*20090403_yabuki_ST297 END*/
      ;
      --
/*20090403_yabuki_ST297 START*/
    -- 処理件数を設定
    on_rec_count := cn_one;
/*20090403_yabuki_ST297 END*/
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 該当データが存在しない場合
/*20090403_yabuki_ST297 START*/
        -- 何も処理しない（→正常かつ処理件数=0）
        NULL;
--        lv_errbuf := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
--                       , iv_name         => cv_tkn_number_07          -- メッセージコード
--                       , iv_token_name1  => cv_tkn_req_num            -- トークンコード1
--                       , iv_token_value1 => iv_requisition_number     -- トークン値1
--                    );
--        --
--        RAISE sql_expt;
/*20090403_yabuki_ST297 END*/
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_08          -- メッセージコード
                       , iv_token_name1  => cv_tkn_table              -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_requisition    -- トークン値1
/*20090403_yabuki_ST297 START*/
                       , iv_token_name2  => cv_tkn_req_header_num     -- トークンコード2
--                       , iv_token_name2  => cv_tkn_req_num            -- トークンコード2
/*20090403_yabuki_ST297 END*/
                       , iv_token_value2 => iv_requisition_number     -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg            -- トークンコード3
                       , iv_token_value3 => SQLERRM                   -- トークン値3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** データ取得SQL例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_requisition_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : input_check
   * Description      : 入力チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE input_check(
      iv_chk_kbn         IN         VARCHAR2             -- チェック区分
    , i_requisition_rec  IN         g_requisition_rtype  -- 発注依頼情報
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    , id_process_date    IN         DATE                 -- 業務処理日付
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'input_check';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_wk_hp_time_type_asgn      CONSTANT VARCHAR2(1) := '1';  -- 作業希望時間区分=「指定」
    cv_inst_place_type_interior  CONSTANT VARCHAR2(1) := '2';  -- 設置場所区分=「屋内」
/*20090413_yabuki_ST170 START*/
    cv_date_fmt                  CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
    cv_date_fmt2                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
    cv_date_yymm_fmt             CONSTANT VARCHAR2(8)  := 'YYYYMM';
    cv_date_yymm_fmt_fx          CONSTANT VARCHAR2(10) := 'FXYYYYMMDD';
    cv_maker_prefix              CONSTANT VARCHAR2(2)  := '11';   --作業会社CDの頭2桁メーカーを表す
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
/*20090413_yabuki_ST170 END*/
/*20090413_yabuki_ST171 START*/
    cv_inst_place_type_exterior  CONSTANT VARCHAR2(1) := '1';  -- 設置場所区分=「屋外」
/*20090413_yabuki_ST171 END*/
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    cv_working_day               CONSTANT VARCHAR2(100) := 'XXCSO1_WORKING_DAY'; -- プロファイル「XXCSO:営業日数」
    cv_zero                      CONSTANT VARCHAR2(2)   := '0';
    cv_maker_prefix2             CONSTANT VARCHAR2(2)   := '10'; -- 作業会社CDの頭2桁メーカーを表す
    cv_base_prefix               CONSTANT VARCHAR2(2)   := '02'; -- 作業会社CDの頭2桁拠点を表す
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    /* 2010.04.19 T.Maruyama E_本稼動_02251 START */
    cv_prfl_hoped_chck_cal       CONSTANT VARCHAR2(100) := 'XXCSO1_HOPEDATE_CHECK_CAL'; -- プロファイル「XXCSO:作業希望日チェック時カレンダ名」
    /* 2010.04.19 T.Maruyama E_本稼動_02251 END */
    --
    -- トークン用定数
    cv_tkn_val_un_number         CONSTANT VARCHAR2(100) := '機種コード';
    cv_tkn_val_install_cd        CONSTANT VARCHAR2(100) := '設置用物件コード';
    cv_tkn_val_wthdrw_inst_cd    CONSTANT VARCHAR2(100) := '引揚用物件コード';
    cv_tkn_val_inst_at_cust_cd   CONSTANT VARCHAR2(100) := '設置先_顧客コード';
    cv_tkn_val_wk_company_cd     CONSTANT VARCHAR2(100) := '作業会社コード';
    cv_tkn_val_wk_location_cd    CONSTANT VARCHAR2(100) := '事業所コード';
    cv_tkn_val_wthdrw_cmpny_cd   CONSTANT VARCHAR2(100) := '引揚会社コード';
    cv_tkn_val_wthdrw_loc_cd     CONSTANT VARCHAR2(100) := '引揚事業所コード';
    cv_tkn_val_ablsh_inst_cd     CONSTANT VARCHAR2(100) := '廃棄_物件コード';
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
    cv_tkn_val_inst_plc_flr      CONSTANT VARCHAR2(100) := '設置場所階数';
    cv_tkn_val_ele_maguchi       CONSTANT VARCHAR2(100) := 'エレベータ間口';
    cv_tkn_val_ele_okuyuki       CONSTANT VARCHAR2(100) := 'エレベータ奥行き';
    cv_tkn_val_hankaku_3_fmt     CONSTANT VARCHAR2(100) := '半角英数3文字以内';
    cv_tkn_val_num_3_fmt         CONSTANT VARCHAR2(100) := '半角数字3文字以内';    
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
    /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
    cv_hyphen                    CONSTANT VARCHAR2(1)   := '-';
    cv_tkn_val_cust_name         CONSTANT VARCHAR2(100) := '設置先_顧客名';
    cv_tkn_val_zip               CONSTANT VARCHAR2(100) := '設置先_郵便番号';
    cv_tkn_val_prfcts            CONSTANT VARCHAR2(100) := '設置先_都道府県';
    cv_tkn_val_city              CONSTANT VARCHAR2(100) := '設置先_市・区';
    cv_tkn_val_addr1             CONSTANT VARCHAR2(100) := '設置先_住所１';
    cv_tkn_val_addr2             CONSTANT VARCHAR2(100) := '設置先_住所２';
    cv_tkn_val_phone             CONSTANT VARCHAR2(100) := '設置先_電話番号';
    cv_tkn_val_emp_nm            CONSTANT VARCHAR2(100) := '設置先_担当者名';
    cv_tkn_val_cust_name_fmt     CONSTANT VARCHAR2(100) := '全角20文字以内';
    cv_tkn_val_zip_fmt           CONSTANT VARCHAR2(100) := '半角数字7文字以内';
    cv_tkn_val_prfcts_fmt        CONSTANT VARCHAR2(100) := '全角4文字以内';
    cv_tkn_val_city_fmt          CONSTANT VARCHAR2(100) := '全角10文字以内';
    cv_tkn_val_addr1_fmt         CONSTANT VARCHAR2(100) := '全角10文字以内';
    cv_tkn_val_addr2_fmt         CONSTANT VARCHAR2(100) := '全角20文字以内';
    cv_tkn_val_phone_fmt         CONSTANT VARCHAR2(100) := '半角数字、「XX-XXXX-XXXX」の形式（各6桁以内）';
    cv_tkn_val_emp_nm_fmt        CONSTANT VARCHAR2(100) := '全角10文字以内';
    cv_temp_info                 CONSTANT VARCHAR2(100) := '情報テンプレート';
    /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
    cv_cust_mast                 CONSTANT VARCHAR2(100) := '顧客マスタ';
    /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
    -- 情報テンプレート取得用パラメータ
    cv_inst_at_cstmr_nm          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_CUSTOMER_NAME';   -- 設置先顧客名
    cv_inst_at_zp                CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ZIP';             -- 設置先_郵便番号
    cv_inst_at_prfcturs          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_PREFECTURES';     -- 設置先都道府県
    cv_inst_at_cty               CONSTANT VARCHAR2(100) :=  'INSTALL_AT_CITY';            -- 設置先市区
    cv_inst_at_addr1             CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ADDR1';           -- 設置先住所１
    cv_inst_at_addr2             CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ADDR2';           -- 設置先住所２
    cv_inst_at_phn               CONSTANT VARCHAR2(100) :=  'INSTALL_AT_PHONE';           -- 設置先電話番号
    cv_inst_at_emply_nm          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_EMPLOYEE_NAME';   -- 設置先担当者名
    /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
    --
    -- *** ローカル変数 ***
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    
    /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
    ln_cnt_rec     NUMBER;
    /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
    ld_wk_date     DATE;
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    lv_working_day VARCHAR2(2000);
    ld_working_day DATE;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
    ln_num1                      NUMBER;            -- 1回目のハイフンの位置
    ln_num2                      NUMBER;            -- 2回目のハイフンの位置
    lv_inst_at_phone1            VARCHAR2(100);     -- 分割後 設置先電話番号1
    lv_inst_at_phone2            VARCHAR2(100);     -- 分割後 設置先電話番号2
    lv_inst_at_phone3            VARCHAR2(100);     -- 分割後 設置先電話番号3
    --
    lv_inst_at_cust_name         VARCHAR2(4000);    -- 設置先顧客名
    lv_inst_at_zip               VARCHAR2(4000);    -- 設置先_郵便番号
    lv_inst_at_prfcturs          VARCHAR2(4000);    -- 設置先都道府県
    lv_inst_at_city              VARCHAR2(4000);    -- 設置先市区
    lv_inst_at_addr1             VARCHAR2(4000);    -- 設置先住所１
    lv_inst_at_addr2             VARCHAR2(4000);    -- 設置先住所２
    lv_inst_at_phone             VARCHAR2(4000);    -- 設置先電話番号
    lv_inst_at_emp_name          VARCHAR2(4000);    -- 設置先担当者名
    /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    lv_errbuf3     VARCHAR2(5000);  -- エラー・メッセージ
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
    --
    -- *** ローカル例外 ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- チェック区分が「機種コード必須入力チェック」の場合
    IF ( iv_chk_kbn = cv_input_chk_kbn_01 ) THEN
      -- 機種コードが未入力の場合
      IF ( i_requisition_rec.un_number IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_09          -- メッセージコード
                       , iv_token_name1  => cv_tkn_item               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_un_number      -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「設置用物件コード必須入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_02 ) THEN
      -- 設置用物件コードが未入力の場合
      IF ( i_requisition_rec.install_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_09          -- メッセージコード
                       , iv_token_name1  => cv_tkn_item               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_install_cd     -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「設置用物件コード入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_03 ) THEN
      -- 設置用物件コードが入力されている場合
      IF ( i_requisition_rec.install_code IS NOT NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_10          -- メッセージコード
                       , iv_token_name1  => cv_tkn_item               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_install_cd     -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「引揚用物件コード入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_04 ) THEN
      -- 引揚用物件コードが入力されている場合
      IF ( i_requisition_rec.withdraw_install_code IS NOT NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_10           -- メッセージコード
                       , iv_token_name1  => cv_tkn_item                -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_wthdrw_inst_cd  -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「引揚用物件コード必須入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_05 ) THEN
      -- 引揚用物件コードが未入力の場合
      IF ( i_requisition_rec.withdraw_install_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_09           -- メッセージコード
                       , iv_token_name1  => cv_tkn_item                -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_wthdrw_inst_cd  -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「設置先_顧客コード必須入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_06 ) THEN
      -- 設置先_顧客コードが未入力の場合
      IF ( i_requisition_rec.install_at_customer_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_09            -- メッセージコード
                       , iv_token_name1  => cv_tkn_item                 -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_inst_at_cust_cd  -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「作業関連情報入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_07 ) THEN
      -- 作業会社コードが未入力の場合
      IF ( i_requisition_rec.work_company_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09          -- メッセージコード
                        , iv_token_name1  => cv_tkn_item               -- トークンコード1
                        , iv_token_value1 => cv_tkn_val_wk_company_cd  -- トークン値1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 事業所コードが未入力の場合
      IF ( i_requisition_rec.work_location_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09           -- メッセージコード
                        , iv_token_name1  => cv_tkn_item                -- トークンコード1
                        , iv_token_value1 => cv_tkn_val_wk_location_cd  -- トークン値1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 作業希望時間区分が「指定」の場合
      IF ( SUBSTRB( i_requisition_rec.work_hope_time_type, 1, 1 ) = cv_wk_hp_time_type_asgn ) THEN
        -- 作業希望時、作業希望分のいずれかが未入力の場合
        IF ( i_requisition_rec.work_hope_time_hour IS NULL 
             OR i_requisition_rec.work_hope_time_minute IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_11          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
      -- 作業希望日の妥当性チェック
      IF (i_requisition_rec.work_hope_year  ||
          i_requisition_rec.work_hope_month ||
          i_requisition_rec.work_hope_day) IS NOT NULL
      THEN
        BEGIN
          -- 1.日付の妥当性チェック
          SELECT TO_DATE(i_requisition_rec.work_hope_year
                      || i_requisition_rec.work_hope_month
                      || i_requisition_rec.work_hope_day, cv_date_yymm_fmt_fx)
          INTO   ld_wk_date
          FROM   DUAL
          ;
          --
          -- 2.２ヶ月以内チェック
          IF TO_CHAR(ADD_MONTHS(xxccp_common_pkg2.get_process_date,2),cv_date_yymm_fmt)
             < TO_CHAR(ld_wk_date,cv_date_yymm_fmt)
          THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                              iv_application => cv_sales_appl_short_name -- アプリケーション短縮名
                            , iv_name        => cv_tkn_number_56         -- メッセージコード
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
          END IF;
--
          /* 2010.07.29 M.Watanabe E_本稼動_03239 START */
          -- 3営業日ルールは 新台設置/新台代替 のみ
          --
          IF ( i_requisition_rec.category_kbn IN (  cv_category_kbn_new_install
                                                  , cv_category_kbn_new_replace ) ) THEN
          /* 2010.07.29 M.Watanabe E_本稼動_03239 END */
--
            /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
            -- 3.３営業日より後かどうかチェック
            --
            -- プロファイル値取得（XXCSO:営業日数）
            FND_PROFILE.GET(
                            cv_working_day
                           ,lv_working_day
                           );
            -- 取得できなかった場合は「0」を設定
            IF (lv_working_day IS NULL) THEN
              lv_working_day := cv_zero;
            END IF;
            --
            -- 業務処理日＋３営業日を取得
            /* 2010.04.19 T.Maruyama E_本稼動_02251 START */
            --ld_working_day := xxccp_common_pkg2.get_working_day(id_process_date,TO_NUMBER(lv_working_day));
            ld_working_day := xxccp_common_pkg2.get_working_day(id_date          => id_process_date
                                                               ,in_working_day   => TO_NUMBER(lv_working_day)
                                                               ,iv_calendar_code => FND_PROFILE.VALUE(cv_prfl_hoped_chck_cal));
            /* 2010.04.19 T.Maruyama E_本稼動_02251 END */
            -- 作業希望日が、業務処理日＋３営業日以前の場合はエラー
            IF (ld_wk_date <= ld_working_day) THEN
              --
              lv_errbuf2 := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                              , iv_name         => cv_tkn_number_65         -- メッセージコード
                              , iv_token_name1  => cv_tkn_date              -- トークンコード1
                              , iv_token_value1 => lv_working_day           -- トークン値1
                            );
              /* 2010.04.01 maruyama E_本稼動_02133 一時的に基準営業日を出力 start */
              lv_errbuf2 := lv_errbuf2 || '(' || to_char(ld_wk_date,'yyyy/mm/dd')|| '：' || to_char(ld_working_day,'yyyy/mm/dd') || ')';
              /* 2010.04.01 maruyama E_本稼動_02133 一時的に基準営業日を出力 end */
              --
              lv_errbuf  := CASE
                              WHEN (lv_errbuf IS NULL) THEN
                                lv_errbuf2
                              ELSE
                                SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                            END;
              --
              ov_retcode := cv_status_warn;
              --
            END IF;
            /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
            --
--
          /* 2010.07.29 M.Watanabe E_本稼動_03239 START */
          END IF;
          /* 2010.07.29 M.Watanabe E_本稼動_03239 END */
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                              iv_application => cv_sales_appl_short_name -- アプリケーション短縮名
                            , iv_name        => cv_tkn_number_56         -- メッセージコード
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
        END;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
/*20090413_yabuki_ST170 START*/
      /* 2009.11.30 K.Satomura E_本稼動_00204対応 START */
      -- 依頼日 ＞ 作業希望日（作業希望年||作業希望月||作業希望日）の場合
      --IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
      --      > i_requisition_rec.work_hope_year
      --         || i_requisition_rec.work_hope_month
      --         || i_requisition_rec.work_hope_day ) THEN
      --  lv_errbuf2 := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
      --                  , iv_name         => cv_tkn_number_46          -- メッセージコード
      --                  , iv_token_name1  => cv_tkn_req_date           -- トークンコード1
      --                  , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- トークン値1
      --                );
      --  --
      --  lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
      --                     THEN lv_errbuf2
      --                     ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      --  ov_retcode := cv_status_warn;
      --  --
      --END IF;
      /* 2009.11.30 K.Satomura E_本稼動_00204対応 END */
      /* 2009.12.07 K.Satomura E_本稼動_00336対応 START */
      -- 依頼日 ＞ 作業希望日（作業希望年||作業希望月||作業希望日）の場合
      IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
            > i_requisition_rec.work_hope_year
               || i_requisition_rec.work_hope_month
               || i_requisition_rec.work_hope_day ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_46          -- メッセージコード
                        , iv_token_name1  => cv_tkn_req_date           -- トークンコード1
                        , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- トークン値1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.12.07 K.Satomura E_本稼動_00336対応 END */
/*20090413_yabuki_ST170 END*/
      --
/*20090413_yabuki_ST171 START*/
      -- 設置場所区分が「屋外」の場合
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_exterior ) THEN
        -- 設置場所階数が入力されている場合
        IF ( i_requisition_rec.install_place_floor IS NOT NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_47          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
/*20090413_yabuki_ST171 END*/
      --
      -- 設置場所区分が「屋内」の場合
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_interior ) THEN
        -- 設置場所階数が未入力の場合
        IF ( i_requisition_rec.install_place_floor IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_12          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        -- 設置場所階数書式チェック(半角英数・3バイト)
        IF (xxccp_common_pkg.chk_alphabet_number_only(i_requisition_rec.install_place_floor) = FALSE) 
          OR LENGTHB(i_requisition_rec.install_place_floor) > 3
        THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_57         -- メッセージコード
                          ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                          ,iv_token_value1 => cv_tkn_val_inst_plc_flr  -- トークン値1
                          ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                          ,iv_token_value2 => cv_tkn_val_hankaku_3_fmt -- トークン値2
                        );
          --
          lv_errbuf  := CASE
                          WHEN (lv_errbuf IS NULL) THEN
                            lv_errbuf2
                          ELSE
                            SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                        END;
          --
          ov_retcode := cv_status_warn;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
      END IF;
      --
      -- エレベータ間口、エレベータ奥行きのどちらか一方のみ入力されている場合
      IF ( i_requisition_rec.elevator_frontage IS NULL AND i_requisition_rec.elevator_depth IS NOT NULL
           OR i_requisition_rec.elevator_frontage IS NOT NULL AND i_requisition_rec.elevator_depth IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_13          -- メッセージコード
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
      -- エレベータ間口書式チェック(半角数字・3バイト)
      IF (i_requisition_rec.elevator_frontage IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_frontage) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_frontage) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_ele_maguchi   -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- エレベータ奥行書式チェック(半角数字・3バイト)
      IF (i_requisition_rec.elevator_depth IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_depth) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_depth) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_ele_okuyuki   -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
      --
      -- 延長コード区分が入力されている場合
      IF ( i_requisition_rec.extension_code_type IS NOT NULL ) THEN
        -- 延長コード(m)が未入力の場合
        IF ( i_requisition_rec.extension_code_meter IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_14          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
    -- チェック区分が「引揚関連情報入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_08 ) THEN
      -- 引揚会社コードが未入力の場合
      IF ( i_requisition_rec.withdraw_company_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09            -- メッセージコード
                        , iv_token_name1  => cv_tkn_item                 -- トークンコード1
                        , iv_token_value1 => cv_tkn_val_wthdrw_cmpny_cd  -- トークン値1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 引揚事業所コードが未入力の場合
      IF ( i_requisition_rec.withdraw_location_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09          -- メッセージコード
                        , iv_token_name1  => cv_tkn_item               -- トークンコード1
                        , iv_token_value1 => cv_tkn_val_wthdrw_loc_cd  -- トークン値1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「廃棄_物件コード必須入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_09 ) THEN
      -- 廃棄_物件コードが未入力の場合
      IF ( i_requisition_rec.abolishment_install_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_09          -- メッセージコード
                       , iv_token_name1  => cv_tkn_item               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_ablsh_inst_cd  -- トークン値1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
/*20090413_yabuki_ST170_ST171 START*/
    -- チェック区分が「引揚関連情報入力チェック２」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_10 ) THEN
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */ 
      -- 引揚の場合も作業会社・作業事業所は指定する必要有。
      -- 作業会社コードが未入力の場合
      IF (i_requisition_rec.work_company_code IS NULL) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_09         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_wk_company_cd -- トークン値1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 事業所コードが未入力の場合
      IF (i_requisition_rec.work_location_code IS NULL) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_09          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_item               -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_wk_location_cd -- トークン値1
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN 
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
      -- 引揚会社コードが未入力の場合
      IF ( i_requisition_rec.withdraw_company_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09            -- メッセージコード
                        , iv_token_name1  => cv_tkn_item                 -- トークンコード1
                        , iv_token_value1 => cv_tkn_val_wthdrw_cmpny_cd  -- トークン値1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 引揚事業所コードが未入力の場合
      IF ( i_requisition_rec.withdraw_location_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09          -- メッセージコード
                        , iv_token_name1  => cv_tkn_item               -- トークンコード1
                        , iv_token_value1 => cv_tkn_val_wthdrw_loc_cd  -- トークン値1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 作業希望時間区分が「指定」の場合
      IF ( SUBSTRB( i_requisition_rec.work_hope_time_type, 1, 1 ) = cv_wk_hp_time_type_asgn ) THEN
        -- 作業希望時、作業希望分のいずれかが未入力の場合
        IF ( i_requisition_rec.work_hope_time_hour IS NULL 
             OR i_requisition_rec.work_hope_time_minute IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_11          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
      -- 作業希望日の妥当性チェック
      IF (i_requisition_rec.work_hope_year || i_requisition_rec.work_hope_month
         || i_requisition_rec.work_hope_day ) IS NOT NULL
      THEN
        BEGIN
          -- 1.日付の妥当性チェック
          SELECT TO_DATE(i_requisition_rec.work_hope_year || i_requisition_rec.work_hope_month
                         || i_requisition_rec.work_hope_day, cv_date_yymm_fmt_fx)
          INTO   ld_wk_date
          FROM   DUAL;
          --
          -- 2.２ヶ月以内チェック
          IF TO_CHAR(ADD_MONTHS(xxccp_common_pkg2.get_process_date,2),cv_date_yymm_fmt) 
             < TO_CHAR(ld_wk_date,cv_date_yymm_fmt)
          THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                              iv_application => cv_sales_appl_short_name -- アプリケーション短縮名
                            , iv_name        => cv_tkn_number_56         -- メッセージコード
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
          END IF;
--
          /* 2010.07.29 M.Watanabe E_本稼動_03239 START */
          -- 引揚の場合、3営業日ルールのチェックは実施しない。
          -- コメントアウト。
--
          -- /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          -- -- 3.３営業日より後かどうかチェック
          -- --
          -- -- プロファイル値取得（XXCSO:営業日数）
          -- FND_PROFILE.GET(
          --                 cv_working_day
          --                ,lv_working_day
          --                );
          -- -- 取得できなかった場合は「0」を設定
          -- IF (lv_working_day IS NULL) THEN
          --   lv_working_day := cv_zero;
          -- END IF;
          -- --
          -- -- 業務処理日＋３営業日を取得
          -- /* 2010.04.19 T.Maruyama E_本稼動_02251 START */
          -- --ld_working_day := xxccp_common_pkg2.get_working_day(id_process_date,TO_NUMBER(lv_working_day));
          -- ld_working_day := xxccp_common_pkg2.get_working_day(id_date          => id_process_date
          --                                                    ,in_working_day   => TO_NUMBER(lv_working_day)
          --                                                    ,iv_calendar_code => FND_PROFILE.VALUE(cv_prfl_hoped_chck_cal));
          -- /* 2010.04.19 T.Maruyama E_本稼動_02251 END */
          -- -- 作業希望日が、業務処理日＋３営業日以前の場合はエラー
          -- IF (ld_wk_date <= ld_working_day) THEN
          --   --
          --   lv_errbuf2 := xxccp_common_pkg.get_msg(
          --                     iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
          --                   , iv_name         => cv_tkn_number_65         -- メッセージコード
          --                   , iv_token_name1  => cv_tkn_date              -- トークンコード1
          --                   , iv_token_value1 => lv_working_day           -- トークン値1
          --                 );
          --   /* 2010.04.01 maruyama E_本稼動_02133 一時的に基準営業日を出力 start */
          --   lv_errbuf2 := lv_errbuf2 || '(' || to_char(ld_wk_date,'yyyy/mm/dd')|| '：' || to_char(ld_working_day,'yyyy/mm/dd') || ')';
          --   /* 2010.04.01 maruyama E_本稼動_02133 一時的に基準営業日を出力 end */
          --   --
          --   --
          --   lv_errbuf  := CASE
          --                   WHEN (lv_errbuf IS NULL) THEN
          --                     lv_errbuf2
          --                   ELSE
          --                     SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
          --                 END;
          --   --
          --   ov_retcode := cv_status_warn;
          --   --
          -- END IF;
          -- /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          --
--
          /* 2010.07.29 M.Watanabe E_本稼動_03239 END */
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                             iv_application => cv_sales_appl_short_name -- アプリケーション短縮名
                            ,iv_name        => cv_tkn_number_56         -- メッセージコード
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
        END;
        -- 
      END IF;
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */

      -- 依頼日 ＞ 作業希望日（作業希望年||作業希望月||作業希望日）の場合
      /* 2009.11.30 K.Satomura E_本稼動_00204対応 START */
      --IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
      --      > i_requisition_rec.work_hope_year
      --         || i_requisition_rec.work_hope_month
      --         || i_requisition_rec.work_hope_day ) THEN
      --  lv_errbuf2 := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
      --                  , iv_name         => cv_tkn_number_46          -- メッセージコード
      --                  , iv_token_name1  => cv_tkn_req_date           -- トークンコード1
      --                  , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- トークン値1
      --                );
      --  --
      --  lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
      --                     THEN lv_errbuf2
      --                     ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      --  ov_retcode := cv_status_warn;
      --  --
      --END IF;
      /* 2009.11.30 K.Satomura E_本稼動_00204対応 END */
      /* 2009.12.07 K.Satomura E_本稼動_00336対応 START */
      IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
            > i_requisition_rec.work_hope_year
               || i_requisition_rec.work_hope_month
               || i_requisition_rec.work_hope_day ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_46          -- メッセージコード
                        , iv_token_name1  => cv_tkn_req_date           -- トークンコード1
                        , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- トークン値1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.12.07 K.Satomura E_本稼動_00336対応 END */
      --
      -- 設置場所区分が「屋外」の場合
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_exterior ) THEN
        -- 設置場所階数が入力されている場合
        IF ( i_requisition_rec.install_place_floor IS NOT NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_47          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      -- 設置場所区分が「屋内」の場合
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_interior ) THEN
        -- 設置場所階数が未入力の場合
        IF ( i_requisition_rec.install_place_floor IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_12          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        -- 設置場所階数書式チェック(半角英数・3バイト)
        IF (xxccp_common_pkg.chk_alphabet_number_only(i_requisition_rec.install_place_floor) = FALSE)
          OR LENGTHB(i_requisition_rec.install_place_floor) > 3
        THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_57         -- メッセージコード
                          ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                          ,iv_token_value1 => cv_tkn_val_inst_plc_flr  -- トークン値1
                          ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                          ,iv_token_value2 => cv_tkn_val_hankaku_3_fmt -- トークン値2
                        );
          --
          lv_errbuf  := CASE
                          WHEN (lv_errbuf IS NULL) THEN
                            lv_errbuf2
                          ELSE
                            SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                        END;
          --
          ov_retcode := cv_status_warn;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
        --
      END IF;
      --
      -- エレベータ間口、エレベータ奥行きのどちらか一方のみ入力されている場合
      IF ( i_requisition_rec.elevator_frontage IS NULL AND i_requisition_rec.elevator_depth IS NOT NULL
           OR i_requisition_rec.elevator_frontage IS NOT NULL AND i_requisition_rec.elevator_depth IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_13          -- メッセージコード
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
      -- エレベータ間口書式チェック(半角数字・3バイト)
      IF (i_requisition_rec.elevator_frontage IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_frontage) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_frontage) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_ele_maguchi   -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- エレベータ奥行書式チェック(半角数字・3バイト)
      IF (i_requisition_rec.elevator_depth IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_depth) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_depth) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_ele_okuyuki   -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
      --
      -- 延長コード区分が入力されている場合
      IF ( i_requisition_rec.extension_code_type IS NOT NULL ) THEN
        -- 延長コード(m)が未入力の場合
        IF ( i_requisition_rec.extension_code_meter IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_14          -- メッセージコード
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
/*20090413_yabuki_ST170_ST171 END*/
      --
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
    -- チェック区分が「作業会社メーカーチェック」の場合
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_11) THEN
      -- 新台設置・新台代替の場合に実施
      -- 作業会社がメーカーでない場合エラー＝作業会社CD頭２桁が11がメーカー
      IF SUBSTRB(i_requisition_rec.work_company_code,1,2) <>  cv_maker_prefix THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name        => cv_tkn_number_58         -- メッセージコード
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- チェック区分が「引揚先入力不可チェック」の場合
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_12) THEN
      -- 新台設置/旧台設置/店内移動の場合に実施
      -- 引揚先は入力不可
      IF (i_requisition_rec.withdraw_company_code IS NOT NULL) 
        OR (i_requisition_rec.withdraw_location_code IS NOT NULL)
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name        => cv_tkn_number_59         -- メッセージコード
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
    /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
    -- チェック区分が「顧客関連情報入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_13 ) THEN
      -- =================
      -- 顧客関連情報抽出
      -- =================
      --発注依頼明細情報ビューの不備により、設置先住所２が取得できないが、ビューの改修による他への影響が大きい為、
      --ビューは修正せず関数により直接情報テンプレートの値を取得する。
      BEGIN
        SELECT xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_cstmr_nm)   -- 設置先顧客名
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_zp)         -- 設置先_郵便番号
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_prfcturs)   -- 設置先都道府県
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_cty)        -- 設置先市区
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_addr1)      -- 設置先住所１
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_addr2)      -- 設置先住所２
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_phn)        -- 設置先電話番号
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_emply_nm)   -- 設置先担当者名
        INTO   lv_inst_at_cust_name
              ,lv_inst_at_zip
              ,lv_inst_at_prfcturs
              ,lv_inst_at_city
              ,lv_inst_at_addr1
              ,lv_inst_at_addr2
              ,lv_inst_at_phone
              ,lv_inst_at_emp_name
        FROM  DUAL
        ;
      EXCEPTION
        -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                 -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_08                         -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                             -- トークンコード1
                       , iv_token_value1 => cv_temp_info                             -- トークン値1
                       , iv_token_name2  => cv_tkn_req_header_num                    -- トークンコード2
                       , iv_token_value2 => i_requisition_rec.requisition_number     -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg                           -- トークンコード3
                       , iv_token_value3 => SQLERRM                                  -- トークン値3
                    );
          RAISE global_api_others_expt;
      END;
      -- 設置先顧客名書式チェック(全角文字・40バイト)
      IF (lv_inst_at_cust_name IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_cust_name) = FALSE)
            OR
              (LENGTHB(lv_inst_at_cust_name) > 40)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_cust_name     -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_cust_name_fmt -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先_郵便番号書式チェック(半角数値・7バイト)
      IF (lv_inst_at_zip IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(lv_inst_at_zip) = FALSE)
            OR
              (LENGTHB(lv_inst_at_zip) > 7)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_zip           -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_zip_fmt       -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先都道府県書式チェック(全角文字・8バイト)
      IF (lv_inst_at_prfcturs IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_prfcturs) = FALSE)
            OR
              (LENGTHB(lv_inst_at_prfcturs) > 8)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_prfcts        -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_prfcts_fmt    -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先市区書式チェック(全角文字・20バイト)
      IF (lv_inst_at_city IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_city) = FALSE)
            OR
              (LENGTHB(lv_inst_at_city) > 20)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_city          -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_city_fmt      -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先住所１書式チェック(全角文字・20バイト)
      IF (lv_inst_at_addr1 IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_addr1) = FALSE)
            OR
              (LENGTHB(lv_inst_at_addr1) > 20)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_addr1         -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_addr1_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先住所２書式チェック(全角文字・40バイト)
      IF (lv_inst_at_addr2 IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_addr2) = FALSE)
            OR
              (LENGTHB(lv_inst_at_addr2) > 40)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_addr2         -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_addr2_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先電話番号書式チェック(半角数値・ハイフンを除いて18バイト)
      IF (lv_inst_at_phone IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_tel_format(lv_inst_at_phone) = FALSE)
            OR
              (LENGTHB(REPLACE(lv_inst_at_phone,cv_hyphen,'')) > 18)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_phone         -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_phone_fmt     -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- 設置先電話番号分割後桁数チェック
      IF (lv_inst_at_phone IS NOT NULL) THEN
        -- 電話番号のハイフンの位置を取得
        ln_num1    := INSTR(lv_inst_at_phone, cv_hyphen);
        ln_num2    := INSTR(lv_inst_at_phone, cv_hyphen, 1, 2);
        --
        -- ハイフンが存在する場合、ハイフンの位置で電話番号を分割
        IF (ln_num1 > 0) THEN
          lv_inst_at_phone1 := SUBSTR(lv_inst_at_phone, 1
                                                          , (ln_num1-1));
        END IF;
        IF (ln_num2 > 0) THEN
          lv_inst_at_phone2 := SUBSTR(lv_inst_at_phone, ln_num1 + 1
                                                          , (ln_num2 - ln_num1 - 1));
          lv_inst_at_phone3 := SUBSTR(lv_inst_at_phone, ln_num2 + 1);
        END IF;
        --
        -- 分割後の設置先電話番号が6桁を超える場合はエラー
        IF (NVL(LENGTHB(lv_inst_at_phone1), 0) > 6)
          OR
           (NVL(LENGTHB(lv_inst_at_phone2), 0) > 6)
          OR
           (NVL(LENGTHB(lv_inst_at_phone3), 0) > 6)
        THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_57         -- メッセージコード
                          ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                          ,iv_token_value1 => cv_tkn_val_phone         -- トークン値1
                          ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                          ,iv_token_value2 => cv_tkn_val_phone_fmt     -- トークン値2
                        );
         --
          lv_errbuf  := CASE
                          WHEN (lv_errbuf IS NULL) THEN
                            lv_errbuf2
                          ELSE
                            SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                        END;
          --
          ov_retcode := cv_status_warn;
          --
        END IF;
      END IF;
      --
      -- 設置先担当者名書式チェック(全角文字・20バイト)
      IF (lv_inst_at_emp_name IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_emp_name) = FALSE)
            OR
              (LENGTHB(lv_inst_at_emp_name) > 20)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_57         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_colname           -- トークンコード1
                        ,iv_token_value1 => cv_tkn_val_emp_nm        -- トークン値1
                        ,iv_token_name2  => cv_tkn_format            -- トークンコード2
                        ,iv_token_value2 => cv_tkn_val_emp_nm_fmt    -- トークン値2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    -- チェック区分が「引揚先(搬入先)妥当性チェック」の場合
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_14) THEN
      -- 新台代替/旧台代替/引揚の場合に実施
      -- 引揚先(搬入先)に入力されたCDの頭2桁が「10」、「02」でない場合はエラー
      IF (SUBSTRB(i_requisition_rec.withdraw_company_code,1,2) <> cv_maker_prefix2) 
        AND (SUBSTRB(i_requisition_rec.withdraw_company_code,1,2) <> cv_base_prefix)
      THEN
        lv_errbuf  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_63         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prefix1           -- トークンコード1
                        ,iv_token_value1 => cv_maker_prefix2         -- トークン値1
                        ,iv_token_name2  => cv_tkn_prefix2           -- トークンコード2
                        ,iv_token_value2 => cv_base_prefix           -- トークン値2
                      );
        ov_retcode := cv_status_warn;
        --
      END IF;
    -- チェック区分が「作業会社妥当性チェック」の場合
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_15) THEN
      --
      -- 作業会社CDの頭2桁が「02」の場合はエラー
      IF (SUBSTRB(i_requisition_rec.work_company_code,1,2) = cv_base_prefix) THEN
        lv_errbuf  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_64         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prefix            -- トークンコード1
                        ,iv_token_value1 => cv_base_prefix           -- トークン値1
                      );
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    -- チェック区分が「申告地必須入力チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_16 ) THEN
      -- 申告地が未入力の場合
      IF ( i_requisition_rec.declaration_place IS NULL ) THEN
        lv_errbuf3 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_74         -- メッセージコード
                      );
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_09         -- メッセージコード
                        , iv_token_name1  => cv_tkn_item              -- トークンコード1
                        , iv_token_value1 => lv_errbuf3               -- トークン値1
                      );
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
    /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
    -- チェック区分が「売上・担当拠点妥当性チェック」の場合
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_17 ) THEN
      -- 売上・担当拠点が半角英数以外の場合
      IF ( xxccp_common_pkg.chk_number( i_requisition_rec.sold_charge_base ) = FALSE ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_77         -- メッセージコード
                      );
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
      -- 売上・担当拠点がマスタに存在しない場合
      ELSE
        BEGIN
          SELECT count(1)
          INTO   ln_cnt_rec
          FROM   hz_cust_accounts hca
          WHERE  hca.account_number      =  i_requisition_rec.sold_charge_base -- 売上・担当拠点
          AND    hca.customer_class_code =  '1'                                --【分類区分】1:拠点
          ;
        --
        EXCEPTION
          -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name                 -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_08                         -- メッセージコード
                         , iv_token_name1  => cv_tkn_table                             -- トークンコード1
                         , iv_token_value1 => cv_cust_mast                             -- トークン値1
                         , iv_token_name2  => cv_tkn_req_header_num                    -- トークンコード2
                         , iv_token_value2 => i_requisition_rec.requisition_number     -- トークン値2
                         , iv_token_name3  => cv_tkn_err_msg                           -- トークンコード3
                         , iv_token_value3 => SQLERRM                                  -- トークン値3
                      );
            RAISE global_process_expt;
        END;
        --
        -- 該当データが存在しない場合
        IF ( ln_cnt_rec = 0 ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_77          -- メッセージコード
                       );
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
    /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
    END IF;
    --
    ov_errbuf := lv_errbuf;
    --
  EXCEPTION
    --#################################  固定例外処理部 START   ####################################
    --
    /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
    WHEN global_process_expt THEN
      -- *** 処理部共通例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END input_check;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ib_existence
   * Description      : 物件マスタ存在チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE check_ib_existence(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    , o_instance_rec   OUT NOCOPY g_instance_rtype  -- 物件情報
    , ov_errbuf        OUT NOCOPY VARCHAR2          -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2          -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ib_existence';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_wk_hp_time_type_asgn    CONSTANT VARCHAR2(1) := '1';  -- 作業希望時間区分=「指定」
    --
    -- *** ローカル変数 ***
    lv_errbuf2    VARCHAR2(5000);  -- エラー・メッセージ
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    BEGIN
      SELECT xibv.instance_id                  instance_id            -- インスタンスID
           , NVL( xibv.op_request_flag, 'N' )  op_request_flag        -- 作業依頼中フラグ
           , xibv.jotai_kbn1                   jotai_kbn1             -- 機器状態１（稼動状態）
           , xibv.jotai_kbn3                   jotai_kbn3             -- 機器状態３（廃棄情報）
           , xibv.object_version_number        object_version_number  -- オブジェクトバージョン番号
           /*20090413_yabuki_ST198 START*/
           , xibv.lease_kbn                    lease_kbn              -- リース区分
           /*20090413_yabuki_ST198 END*/
           /*20090427_yabuki_ST505_517 START*/
           , xibv.install_account_id           owner_account_id       -- 設置先アカウントID
           /*20090427_yabuki_ST505_517 END*/
           /* 20090511_abe_ST965 START*/
           , xibv.jotai_kbn2                   jotai_kbn2             -- 機器状態２（状態詳細）
           , xibv.sakujo_flg                   sakujo_flg             -- 削除フラグ
           , xibv.install_code                 install_code           -- 物件コード
           /* 20090511_abe_ST965 END*/
           /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
           , xibv.op_req_number_account_number op_req_number_account_number -- 作業依頼中購買依頼番号/顧客CD
           /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
           , xibv.instance_type_code           instance_type_code     -- インスタンスタイプコード
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
      INTO   o_instance_rec.instance_id  -- インスタンスID
           , o_instance_rec.op_req_flag  -- 作業依頼中フラグ
           , o_instance_rec.jotai_kbn1   -- 機器状態１（稼動状態）
           , o_instance_rec.jotai_kbn3   -- 機器状態３（廃棄情報）
           , o_instance_rec.obj_ver_num  -- オブジェクトバージョン番号
           /*20090413_yabuki_ST198 START*/
           , o_instance_rec.lease_kbn    -- リース区分
           /*20090413_yabuki_ST198 END*/
           /*20090427_yabuki_ST505_517 START*/
           , o_instance_rec.owner_account_id  -- 設置先アカウントID
           /*20090427_yabuki_ST505_517 END*/
           /* 20090511_abe_ST965 START*/
           , o_instance_rec.jotai_kbn2   -- 機器状態２（状態詳細）
           , o_instance_rec.delete_flag  -- 削除フラグ
           , o_instance_rec.install_code -- 物件コード
           /* 20090511_abe_ST965 END*/
           /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
           , o_instance_rec.op_req_number_account_number -- 作業依頼中購買依頼番号/顧客CD
           /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
           , o_instance_rec.instance_type_code -- インスタンスタイプコード
           /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
      FROM   xxcso_install_base_v  xibv
      WHERE  xibv.install_code = iv_install_code
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 該当データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_15          -- メッセージコード
                       , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                       , iv_token_value1 => iv_install_code           -- トークン値1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_16          -- メッセージコード
                       , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                       , iv_token_value1 => iv_install_code           -- トークン値1
                       , iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                       , iv_token_value2 => SQLERRM                   -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** データ取得SQL例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_ib_existence;
  --
/* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
  --
  /**********************************************************************************
   * Procedure Name   : chk_authorization_status
   * Description      : 購買依頼ステータスチェック処理(A-5-0)
   ***********************************************************************************/
  PROCEDURE chk_authorization_status(
      iv_op_req_num    IN         VARCHAR2                                -- 作業依頼中購買依頼番号
    , ob_stts_chk_flg  OUT NOCOPY BOOLEAN                                 -- 購買依頼ステータスチェックフラグ
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_authorization_status';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_status_returned        CONSTANT VARCHAR2(10) := 'RETURNED';         -- 購買依頼ステータス「差戻」
    cv_status_cancelled       CONSTANT VARCHAR2(10) := 'CANCELLED';        -- 購買依頼ステータス「取消済」
    --
    -- *** ローカル変数 ***
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode2    VARCHAR2(1);     -- リターン・コード
    lt_authorization_status  po_requisition_headers.authorization_status%TYPE;
    --
    -- *** ローカル例外 ***
    chk_authrztn_stts_expt       EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    BEGIN
      SELECT prh.authorization_status  authorization_status -- 購買依頼ステータス
      INTO   lt_authorization_status
      FROM   po_requisition_headers prh
      WHERE  prh.segment1 = iv_op_req_num
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE chk_authrztn_stts_expt;
    END;
    -- 購買依頼ステータスが「差戻」、「取消済」の場合はTRUE
    IF ((lt_authorization_status = cv_status_returned)
         OR (lt_authorization_status = cv_status_cancelled)) THEN
      --
      ob_stts_chk_flg := cb_true;
    ELSE
    -- 購買依頼ステータスが「差戻」、「取消済」以外の場合はFALSE
      ob_stts_chk_flg := cb_false;
    END IF;
      --
    --
  EXCEPTION
    WHEN chk_authrztn_stts_expt THEN
      -- *** SQLデータ抽出例外 ***
      -- 購買依頼ステータスが抽出できなかったはFALSE
      ob_stts_chk_flg := cb_false;
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END chk_authorization_status;
  --
  --
/* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
  --
  /**********************************************************************************
   * Procedure Name   : check_ib_info
   * Description      : 設置用物件情報チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE check_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    , i_instance_rec   IN         g_instance_rtype                        -- 物件情報
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode2    VARCHAR2(1);     -- リターン・コード
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    lb_stts_chk_flg BOOLEAN;        -- 購買依頼ステータスチェック処理 戻り値
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    -- *** ローカル例外 ***
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- 処理区分が「発注依頼申請」の場合
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        -- 作業依頼中フラグ_設置用がＯＮの場合
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-5-0. 購買依頼ステータスチェック処理
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- 作業依頼中購買依頼番号
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- 購買依頼ステータスチェックフラグ
          , ov_errbuf        => lv_errbuf                      -- エラー・メッセージ  --# 固定 #
          , ov_retcode       => lv_retcode                     -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- 購買依頼ステータスチェックフラグがFALSEの場合、チェックエラーとする
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_17          -- メッセージコード
                          , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                          , iv_token_value1 => iv_install_code           -- トークン値1
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
                          , iv_token_name2  => cv_tkn_req_num                                -- トークンコード2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- トークン値2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- トークンコード3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- トークン値3
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
      END IF;
      --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- 処理区分が「発注依頼承認」の場合
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- 作業依頼中フラグ_設置用がＯＦＦの場合
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_60         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_sagyo             -- トークンコード1
                        ,iv_token_value1 => cv_tkn_install           -- トークン値1
                        ,iv_token_name2  => cv_tkn_bukken            -- トークンコード2
                        ,iv_token_value2 => iv_install_code          -- トークン値2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    -- 機器状態１（稼動状態）がNULLまたは「滞留」以外の場合
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_hold )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                      , iv_name         => cv_tkn_number_18           -- メッセージコード
                      , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                      , iv_token_value1 => iv_install_code            -- トークン値1
                      , iv_token_name2  => cv_tkn_status1             -- トークンコード2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- トークン値2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- 機器状態３（廃棄情報）がNULLまたは「0:予定無」および「1:廃棄予定」以外の場合
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
      /* 2009.11.25 K.Satomura E_本稼動_00027対応 START */
      OR (   
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
           AND
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_pln )
           )
      --OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
      /* 2009.11.25 K.Satomura E_本稼動_00027対応 END */
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                      , iv_name         => cv_tkn_number_19           -- メッセージコード
                      , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                      , iv_token_value1 => iv_install_code            -- トークン値1
                      , iv_token_name2  => cv_tkn_status3             -- トークンコード2
                      , iv_token_value2 => i_instance_rec.jotai_kbn3  -- トークン値2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- チェックでエラーがあった場合
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    WHEN chk_status_expt THEN
      -- *** SQLデータ抽出例外 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_withdraw_ib_info
   * Description      : 引揚用物件情報チェック処理(A-6)
   ***********************************************************************************/
  PROCEDURE check_withdraw_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    , i_instance_rec   IN         g_instance_rtype                        -- 物件情報
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_withdraw_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode2    VARCHAR2(1);     -- リターン・コード
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    lb_stts_chk_flg BOOLEAN;        -- 購買依頼ステータスチェック処理 戻り値
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    -- *** ローカル例外 ***
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- 処理区分が「発注依頼申請」の場合
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        -- 作業依頼中フラグがＯＮの場合
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-5-0. 購買依頼ステータスチェック処理
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- 作業依頼中購買依頼番号
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- 購買依頼ステータスチェックフラグ
          , ov_errbuf        => lv_errbuf                      -- エラー・メッセージ  --# 固定 #
          , ov_retcode       => lv_retcode                     -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- 購買依頼ステータスチェックフラグがFALSEの場合、チェックエラーとする
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_20          -- メッセージコード
                          , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                          , iv_token_value1 => iv_install_code           -- トークン値1
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
                          , iv_token_name2  => cv_tkn_req_num                                -- トークンコード2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- トークン値2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- トークンコード3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- トークン値3
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
      END IF;
      --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- 処理区分が「発注依頼承認」の場合
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- 作業依頼中フラグ_設置用がＯＦＦの場合
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_60         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_sagyo             -- トークンコード1
                        ,iv_token_value1 => cv_tkn_withdraw          -- トークン値1
                        ,iv_token_name2  => cv_tkn_bukken            -- トークンコード2
                        ,iv_token_value2 => iv_install_code          -- トークン値2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    -- 機器状態１（稼動状態）がNULLまたは「稼動」以外の場合
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_operate )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                      , iv_name         => cv_tkn_number_21           -- メッセージコード
                      , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                      , iv_token_value1 => iv_install_code            -- トークン値1
                      , iv_token_name2  => cv_tkn_status1             -- トークンコード2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- トークン値2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    --
    -- チェックでエラーがあった場合
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    WHEN chk_status_expt THEN
      -- *** SQLデータ抽出例外 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_withdraw_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ablsh_appl_ib_info
   * Description      : 廃棄申請用物件情報チェック処理(A-7)
   ***********************************************************************************/
  PROCEDURE check_ablsh_appl_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    , i_instance_rec   IN         g_instance_rtype                        -- 物件情報
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ablsh_appl_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode2    VARCHAR2(1);     -- リターン・コード
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    lb_stts_chk_flg BOOLEAN;        -- 購買依頼ステータスチェック処理 戻り値
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    -- *** ローカル例外 ***
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- 処理区分が「発注依頼申請」の場合
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      -- 作業依頼中フラグがＯＮの場合
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-5-0. 購買依頼ステータスチェック処理
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- 作業依頼中購買依頼番号
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- 購買依頼ステータスチェックフラグ
          , ov_errbuf        => lv_errbuf                      -- エラー・メッセージ  --# 固定 #
          , ov_retcode       => lv_retcode                     -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- 購買依頼ステータスチェックフラグがFALSEの場合、チェックエラーとする
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_22          -- メッセージコード
                          , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                          , iv_token_value1 => iv_install_code           -- トークン値1
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
                          , iv_token_name2  => cv_tkn_req_num                                -- トークンコード2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- トークン値2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- トークンコード3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- トークン値3
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
      END IF;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- 処理区分が「発注依頼承認」の場合
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- 作業依頼中フラグ_設置用がＯＦＦの場合
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_60         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_sagyo             -- トークンコード1
                        ,iv_token_value1 => cv_tkn_ablsh             -- トークン値1
                        ,iv_token_name2  => cv_tkn_bukken            -- トークンコード2
                        ,iv_token_value2 => iv_install_code          -- トークン値2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    --
    -- 機器状態１（稼動状態）がNULLまたは「滞留」以外の場合
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_hold )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                      , iv_name         => cv_tkn_number_23           -- メッセージコード
                      , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                      , iv_token_value1 => iv_install_code            -- トークン値1
                      , iv_token_name2  => cv_tkn_status1             -- トークンコード2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- トークン値2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- 処理区分が「発注依頼申請」の場合
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      -- 機器状態３（廃棄情報）がNULLまたは「予定無」以外の場合
      IF ( i_instance_rec.jotai_kbn3 IS NULL )
        OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_24           -- メッセージコード
                        , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                        , iv_token_value1 => iv_install_code            -- トークン値1
                        , iv_token_name2  => cv_tkn_status3             -- トークンコード2
                        , iv_token_value2 => i_instance_rec.jotai_kbn3  -- トークン値2
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_error;
        --
      END IF;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- 処理区分が「発注依頼承認」の場合
      -- 機器状態３（廃棄情報）がNULLまたは「廃棄申請中」以外の場合
      IF ( i_instance_rec.jotai_kbn3 IS NULL )
        OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_appl )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                        , iv_name         => cv_tkn_number_25           -- メッセージコード
                        , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                        , iv_token_value1 => iv_install_code            -- トークン値1
                        , iv_token_name2  => cv_tkn_status3             -- トークンコード2
                        , iv_token_value2 => i_instance_rec.jotai_kbn3  -- トークン値2
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_error;
      END IF;
    END IF;
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    --
    -- チェックでエラーがあった場合
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    WHEN chk_status_expt THEN
      -- *** SQLデータ抽出例外 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_ablsh_appl_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ablsh_aprv_ib_info
   * Description      : 廃棄決裁用物件情報チェック処理(A-8)
   ***********************************************************************************/
  PROCEDURE check_ablsh_aprv_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    , i_instance_rec   IN         g_instance_rtype                        -- 物件情報
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--    , id_process_date  IN         DATE                                    -- 業務処理日付
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ablsh_aprv_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--    cv_zero                   CONSTANT VARCHAR2(1)  := '0';           -- リース種類「Finリース」
--    cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';           -- 参照タイプ使用可能フラグ「YES」
--    cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';  -- DATE型フォーマット
--    cv_lookup_deprn_year      CONSTANT VARCHAR2(30) := 'XXCSO1_DEPRN_YEAR';  -- 参照タイプ「償却年数」
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
    --
    -- *** ローカル変数 ***
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode2    VARCHAR2(1);     -- リターン・コード
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    lb_stts_chk_flg BOOLEAN;        -- 購買依頼ステータスチェック処理 戻り値
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--    lv_msg                    VARCHAR2(5000);  -- ユーザー・メッセージ(ノート)
--    ld_deprn_date             DATE;            -- 償却日
--    lv_end_deprn_date         VARCHAR2(10);    -- 償却期間終了日(メッセージ出力用)
--    lt_lease_start_date       xxcff_contract_headers.lease_start_date%TYPE;  -- リース開始日
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
    --
    -- *** ローカル例外 ***
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--    chk_target_data_expt  EXCEPTION;
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
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
    /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
    --廃棄決裁時にも作業依頼中フラグの排他チェックを追加
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- 処理区分が「発注依頼申請」の場合
      -- 作業依頼中フラグがＯＮの場合
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-5-0. 購買依頼ステータスチェック処理
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- 作業依頼中購買依頼番号
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- 購買依頼ステータスチェックフラグ
          , ov_errbuf        => lv_errbuf                      -- エラー・メッセージ  --# 固定 #
          , ov_retcode       => lv_retcode                     -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- 購買依頼ステータスチェックフラグがFALSEの場合、チェックエラーとする
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                          , iv_name         => cv_tkn_number_22          -- メッセージコード
                          , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                          , iv_token_value1 => iv_install_code           -- トークン値1
                          , iv_token_name2  => cv_tkn_req_num                                -- トークンコード2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- トークン値2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- トークンコード3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- トークン値3
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
      END IF;
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- 処理区分が「発注依頼承認」の場合
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- 作業依頼中フラグ_設置用がＯＦＦの場合
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_60         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_sagyo             -- トークンコード1
                        ,iv_token_value1 => cv_tkn_ablsh             -- トークン値1
                        ,iv_token_name2  => cv_tkn_bukken            -- トークンコード2
                        ,iv_token_value2 => iv_install_code          -- トークン値2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
--    
    
    -- 機器状態１（稼動状態）がNULLまたは「滞留」以外の場合
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_hold )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                      , iv_name         => cv_tkn_number_23           -- メッセージコード
                      , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                      , iv_token_value1 => iv_install_code            -- トークン値1
                      , iv_token_name2  => cv_tkn_status1             -- トークンコード2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- トークン値2
                    );
      --
      lv_errbuf  := lv_errbuf2;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- 機器状態３（廃棄情報）がNULLまたは「予定無」「廃棄予定」以外の場合
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
    /* 2010.12.07 K.Kiriu E_本稼動_05751対応 START */
--      OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_appl )
      OR (
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
           AND
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_pln )
         )
    /* 2010.12.07 K.Kiriu E_本稼動_05751対応 END */
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                      , iv_name         => cv_tkn_number_25           -- メッセージコード
                      , iv_token_name1  => cv_tkn_bukken              -- トークンコード1
                      , iv_token_value1 => iv_install_code            -- トークン値1
                      , iv_token_name2  => cv_tkn_status3             -- トークンコード2
                      , iv_token_value2 => i_instance_rec.jotai_kbn3  -- トークン値2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
--    -- 処理区分が「発注依頼申請」の場合
--    --
--      -- 物件コードのリース開始日を取得
--      BEGIN
--        SELECT
--               /*+ USE_NL(xxoh xxcl xxch) 
--               INDEX(xxoh XXCFF_OBJECT_HEADERS_U01) */
--               xxch.lease_start_date  lease_start_date --リース開始日
--        INTO
--               lt_lease_start_date
--        FROM   
--               xxcff_object_headers    xxoh  --リース物件
--              ,xxcff_contract_lines    xxcl  --リース契約明細
--              ,xxcff_contract_headers  xxch  --リース契約ヘッダ
--        WHERE
--               xxoh.object_code      = iv_install_code            --物件コード
--        AND    xxoh.object_header_id = xxcl.object_header_id      --物件内部ID
--        AND    xxcl.lease_kind       = cv_zero                    --リース種類(Fin)
--        AND    xxch.contract_header_id = xxcl.contract_header_id  --契約内部ID
--        ;
--      EXCEPTION
--        -- 該当データが存在しない場合
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--        -- 抽出に失敗した場合
--        WHEN OTHERS THEN
--          lv_msg := xxccp_common_pkg.get_msg(
--                          iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
--                         ,iv_name        => cv_tkn_number_69           -- メッセージ
--                       );
--          lv_errbuf := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_68          -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
--                         ,iv_token_value1 => lv_msg                    -- トークン値1
--                         ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
--                         ,iv_token_value2 => SQLERRM                   -- トークン値2
--                       );
--        RAISE chk_target_data_expt;
--      END;
--      --
--      -- リース開始日を取得した場合、償却日を抽出する
--      IF ( lt_lease_start_date IS NOT NULL ) THEN
--      --
--        -- リース開始日から償却日を取得
--        BEGIN
--          SELECT 
--                 ADD_MONTHS( lt_lease_start_date , flvv.attribute1 * 12 ) deprn_date  --償却日
--          INTO
--                 ld_deprn_date
--          FROM   fnd_lookup_values_vl flvv
--          WHERE  flvv.lookup_type  = cv_lookup_deprn_year
--          AND    flvv.enabled_flag = cv_flag_yes
--          AND    flvv.start_date_active <= lt_lease_start_date  --有効開始日
--          AND    flvv.end_date_active   >= lt_lease_start_date  --有効終了日
--          ;
--        EXCEPTION
--          -- 該当データが存在しない場合
--          WHEN NO_DATA_FOUND THEN
--            NULL;
--          -- 抽出に失敗した場合
--          WHEN OTHERS THEN
--            lv_msg := xxccp_common_pkg.get_msg(
--                            iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
--                           ,iv_name        => cv_tkn_number_70           -- メッセージ
--                         );
--            lv_errbuf := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
--                           ,iv_name         => cv_tkn_number_68          -- メッセージコード
--                           ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
--                           ,iv_token_value1 => lv_msg                    -- トークン値1
--                           ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
--                           ,iv_token_value2 => SQLERRM                   -- トークン値2
--                         );
--          RAISE chk_target_data_expt;
--        END;
--      --
--      END IF;
--      --
--      -- 業務日付がリース開始日以上、かつ償却日未満の場合、チェックエラーとする
--      IF ( lt_lease_start_date <= id_process_date ) 
--        AND ( id_process_date < ld_deprn_date ) THEN
--        --
--        lv_end_deprn_date := TO_CHAR(ld_deprn_date - 1, cv_date_fmt);
--        lv_errbuf2 := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
--                        ,iv_name         => cv_tkn_number_67         -- メッセージコード
--                        ,iv_token_name1  => cv_tkn_date              -- トークンコード1
--                        ,iv_token_value1 => lv_end_deprn_date        -- トークン値1
--                      );
--        --
--        lv_errbuf  := lv_errbuf2;
--        ov_retcode := cv_status_error;
--        --
--      END IF;
--    END IF;
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
    --
    -- チェックでエラーがあった場合
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    WHEN chk_status_expt THEN
      -- *** SQLデータ抽出例外 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--    WHEN chk_target_data_expt THEN
--      -- *** 対象データ抽出例外 ***
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_ablsh_aprv_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_mvmt_in_shp_ib_info
   * Description      : 店内移動用物件情報チェック処理(A-9)
   ***********************************************************************************/
  PROCEDURE check_mvmt_in_shp_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    , i_instance_rec   IN         g_instance_rtype                        -- 物件情報
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_mvmt_in_shp_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    lv_errbuf2     VARCHAR2(5000);  -- エラー・メッセージ
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    lb_stts_chk_flg BOOLEAN;        -- 購買依頼ステータスチェック処理 戻り値
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    -- *** ローカル例外 ***
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- 処理区分が「発注依頼申請」の場合
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      -- 作業依頼中フラグがＯＮの場合
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-5-0. 購買依頼ステータスチェック処理
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- 作業依頼中購買依頼番号
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- 購買依頼ステータスチェックフラグ
          , ov_errbuf        => lv_errbuf                      -- エラー・メッセージ  --# 固定 #
          , ov_retcode       => lv_retcode                     -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- 購買依頼ステータスチェックフラグがFALSEの場合、チェックエラーとする
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_17          -- メッセージコード
                         , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                         , iv_token_value1 => iv_install_code           -- トークン値1
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
                          , iv_token_name2  => cv_tkn_req_num                                -- トークンコード2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- トークン値2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- トークンコード3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- トークン値3
                          /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
                       );
          --
          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
      END IF;
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- 処理区分が「発注依頼承認」の場合
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- 作業依頼中フラグ_設置用がＯＦＦの場合
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_60         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_sagyo             -- トークンコード1
                        ,iv_token_value1 => cv_tkn_install           -- トークン値1
                        ,iv_token_name2  => cv_tkn_bukken            -- トークンコード2
                        ,iv_token_value2 => iv_install_code          -- トークン値2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
    WHEN chk_status_expt THEN
      -- *** SQLデータ抽出例外 ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_mvmt_in_shp_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_object_status
   * Description      : 物件ステータスチェック処理(A-10)
   ***********************************************************************************/
  PROCEDURE check_object_status(
      iv_chk_kbn       IN         VARCHAR2                                -- チェック区分
    , iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- 物件コード
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
    , id_process_date  IN         DATE                                    -- 業務処理日付
    , iv_process_kbn   IN         VARCHAR2                                -- 処理区分
    /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    , iv_lease_kbn          IN    VARCHAR2                                -- リース区分
    , iv_instance_type_code IN    VARCHAR2                                -- インスタンスタイプコード
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- エラー・メッセージ --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_object_status';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_obj_sts_contracted          CONSTANT VARCHAR2(3) := '102';  -- 契約済
    cv_obj_sts_re_lease_cntrctd    CONSTANT VARCHAR2(3) := '104';  -- 再リース契約済
    cv_obj_sts_canceled_cnvnnc     CONSTANT VARCHAR2(3) := '110';  -- 中途解約（自己都合）
    cv_obj_sts_canceled_insurance  CONSTANT VARCHAR2(3) := '111';  -- 中途解約（保険対応）
    cv_obj_sts_canceled_expired    CONSTANT VARCHAR2(3) := '112';  -- 中途解約（満了）
    cv_obj_sts_expired             CONSTANT VARCHAR2(3) := '107';  -- 満了
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
    cv_obj_sts_uncontract          CONSTANT VARCHAR2(3) := '101';  -- 未契約
/* 2009.12.16 D.Abe E_本稼動_00498対応 START */
    cv_obj_sts_lease_wait          CONSTANT VARCHAR2(3) := '103';  -- 再リース待
/* 2009.12.16 D.Abe E_本稼動_00498対応 END */
    -- リース区分
    cv_ls_tp_lease_cntrctd         CONSTANT VARCHAR2(1) := '1';    -- 原契約
    cv_ls_tp_re_lease_cntrctd      CONSTANT VARCHAR2(1) := '2';    -- 再リース契約
    -- 証書受領フラグ
    cv_bnd_accpt_flg_accptd        CONSTANT VARCHAR2(1) := '1';    -- 受領済
    --
    cv_yes                         CONSTANT VARCHAR2(1) := 'Y';
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
/* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
    cv_zero                        CONSTANT VARCHAR2(1)  := '0';           -- リース種類「Finリース」
    cv_flag_yes                    CONSTANT VARCHAR2(1)  := 'Y';           -- 参照タイプ使用可能フラグ「YES」
    cv_date_fmt                    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';  -- DATE型フォーマット
    cv_lookup_deprn_year           CONSTANT VARCHAR2(30) := 'XXCSO1_DEPRN_YEAR';  -- 参照タイプ「償却年数」
/* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    -- プロファイル
    cv_prfl_fa_books               CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSETS_BOOKS'; -- XXCFF:台帳名
    -- 参照タイプ
    cv_lookup_csi_type_code        CONSTANT VARCHAR2(30) := 'CSI_INST_TYPE_CODE';        -- インスタンス・タイプ・コード
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
    --
    -- *** ローカル変数 ***
    lv_object_status    xxcff_object_headers.object_status%TYPE;    -- 物件ステータス
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
    lt_lease_type            xxcff_object_headers.lease_type%TYPE;              -- リース区分
    lt_bond_acceptance_flag  xxcff_object_headers.bond_acceptance_flag%TYPE;    -- 証書受領フラグ
    lv_no_data_flg           VARCHAR2(1) DEFAULT 'N';
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
/* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
    lv_msg                   VARCHAR2(5000);      -- ユーザー・メッセージ(ノート)
    ld_deprn_date            DATE;                -- 償却日
    lv_end_deprn_date        VARCHAR2(10);        -- 償却期間終了日(メッセージ出力用)
    lv_no_chk_flag           VARCHAR2(1) := 'N';  -- 償却チェックフラグ
    lt_lease_start_date      xxcff_contract_headers.lease_start_date%TYPE;  -- リース開始日
    lt_lease_class           xxcff_contract_headers.lease_class%TYPE;       -- リース種別
/* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    lt_fa_book_type_code           fa_books.book_type_code%TYPE;            -- 台帳名
    lt_date_placed_in_service      fa_books.date_placed_in_service%TYPE;    -- 事業供用日
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
/* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
    chk_target_data_expt  EXCEPTION;
    chk_deprn_date_expt   EXCEPTION;
/* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    -- リース区分が「自社リース」の場合
    IF ( iv_lease_kbn = cv_own_company_lease ) THEN
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
      -- ========================================
      -- リース物件テーブル抽出
      -- ========================================
      BEGIN
        SELECT xoh.object_status  object_status
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
              ,xoh.lease_type            lease_type
              ,xoh.bond_acceptance_flag  bond_acceptance_flag
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
        INTO   lv_object_status
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
              ,lt_lease_type
              ,lt_bond_acceptance_flag
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
        FROM   xxcff_object_headers  xoh
        WHERE  xoh.object_code = iv_install_code
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 該当データが存在しない場合
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
--        lv_errbuf := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
--                       , iv_name         => cv_tkn_number_26          -- メッセージコード
--                       , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
--                       , iv_token_value1 => iv_install_code           -- トークン値1
--                     );
--        --
--        RAISE sql_expt;
--        --
            lv_object_status := NULL;         -- 物件ステータス
            lt_lease_type    := NULL;         -- リース区分
            lt_bond_acceptance_flag := NULL;  -- 証書受領フラグ
            --
            lv_no_data_flg   := cv_yes;
            --
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
        WHEN OTHERS THEN
          -- その他の例外の場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_28          -- メッセージコード
                         , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                         , iv_token_value1 => iv_install_code           -- トークン値1
                         , iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                         , iv_token_value2 => SQLERRM                   -- トークン値2
                       );
          --
          RAISE sql_expt;
          --
      END;
      -- ========================================
      -- リース物件ステータスチェック
      -- ========================================
      -- チェック対象が設置用物件の場合
      IF ( iv_chk_kbn = cv_obj_sts_chk_kbn_01 ) THEN
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
--      -- 物件ステータスがNULL以外でかつ、「契約済」「再リース契約済」以外の場合
        /* 2009.12.16 D.Abe E_本稼動_00498対応 START */
        ---- 物件ステータスがNULL以外でかつ、「契約済」「再リース契約済」「未契約('101')」以外の場合
        -- 物件ステータスがNULL以外でかつ、「契約済」「再リース契約済」「未契約('101')」「再リース待」以外の場合
        /* 2009.12.16 D.Abe E_本稼動_00498対応 END */
        IF ( lv_object_status IS NOT NULL
--           AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd ) ) THEN
             /* 2009.12.16 D.Abe E_本稼動_00498対応 START */
             --AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd, cv_obj_sts_uncontract ) ) THEN
             AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd, cv_obj_sts_uncontract,
                                           cv_obj_sts_lease_wait ) ) THEN
           /* 2009.12.16 D.Abe E_本稼動_00498対応 END */
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_27          -- メッセージコード
                         , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                         , iv_token_value1 => iv_install_code           -- トークン値1
                       );
          --
          RAISE sql_expt;
          --
        END IF;
        --
      ELSE
        /* 2009.12.16 D.Abe E_本稼動_00354対応 START */
        --  リース物件が存在しない場合
        IF  ( lv_no_data_flg = cv_yes ) THEN
          RETURN;
        END IF;
        --
        /* 2009.12.16 D.Abe E_本稼動_00354対応 END */
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
--      -- 物件ステータスがNULL以外でかつ、
--      -- 「再リース契約済」「中途解約（自己都合）」「中途解約（保険対応）」「中途解約（満了）」「満了」以外の場合
--      IF ( lv_object_status IS NOT NULL
--           AND lv_object_status NOT IN ( cv_obj_sts_re_lease_cntrctd, cv_obj_sts_canceled_cnvnnc, cv_obj_sts_canceled_insurance
--                                         , cv_obj_sts_canceled_expired, cv_obj_sts_expired ) ) THEN
        -- 物件マスタに登録されていない場合または
        IF ( lv_no_data_flg = cv_yes )
          -- 物件ステータスが「満了」、「中途解約（満了）」以外かつ、
          -- 『リース区分が「原契約」かつ物件ステータスが「中途解約(自己都合)」かつ証書受領フラグが「受領済」』以外かつ、
          -- 『リース区分が「原契約」かつ物件ステータスが「中途解約(保険対応)」かつ証書受領フラグが「受領済」』以外かつ、
          -- リース区分が「再リース契約」以外の場合
          OR (         (       lv_object_status NOT IN ( cv_obj_sts_expired, cv_obj_sts_canceled_expired )  )
               AND NOT (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd     )
                         AND ( lv_object_status        = cv_obj_sts_canceled_cnvnnc )
                         AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd    )  )
               AND NOT (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd     )
                         AND ( lv_object_status        = cv_obj_sts_canceled_insurance )
                         AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd    )  )
               AND     (       lt_lease_type <> cv_ls_tp_re_lease_cntrctd           )         ) THEN
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                           , iv_name         => cv_tkn_number_29          -- メッセージコード
                           , iv_token_name1  => cv_tkn_bukken             -- トークンコード1
                           , iv_token_value1 => iv_install_code           -- トークン値1
                         );
            --
            RAISE sql_expt;
            --
        END IF;
        --
/* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
        -- 処理区分が「発注依頼申請」の場合
        IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
          -- 物件ステータスが「中途解約(自己都合)」かつ証書受領フラグが「受領済」』か、
          -- 物件ステータスが「中途解約(保険対応)」かつ証書受領フラグが「受領済」』
          IF (
/* 2014-12-15 K.Kanada E_本稼動_12775対応 START */
--              (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd     )
--                AND ( lv_object_status        = cv_obj_sts_canceled_cnvnnc )
              (     ( lv_object_status        = cv_obj_sts_canceled_cnvnnc )
/* 2014-12-15 K.Kanada E_本稼動_12775対応 END   */
                AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd    ) )
            OR
/* 2014-12-15 K.Kanada E_本稼動_12775対応 START */
--              (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd        )
--                AND ( lv_object_status        = cv_obj_sts_canceled_insurance )
              (     ( lv_object_status        = cv_obj_sts_canceled_insurance )
/* 2014-12-15 K.Kanada E_本稼動_12775対応 END   */
                AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd       ) )
              ) THEN
                lv_no_chk_flag := 'Y'; -- 償却期間チェック対象外
          END IF;
          --
          IF lv_no_chk_flag = 'N' THEN
            -- 物件コードのリース契約情報を取得
            BEGIN
              SELECT
                     /*+ USE_NL(xxoh xxcl xxch) 
                     INDEX(xxoh XXCFF_OBJECT_HEADERS_U01) */
                     xxch.lease_start_date  lease_start_date -- リース開始日
                    ,xxch.lease_class       lease_class      -- リース種別
              INTO
                     lt_lease_start_date
                    ,lt_lease_class
              FROM   
                     xxcff_object_headers    xxoh  --リース物件
                    ,xxcff_contract_lines    xxcl  --リース契約明細
                    ,xxcff_contract_headers  xxch  --リース契約ヘッダ
              WHERE
                     xxoh.object_code      = iv_install_code            -- 物件コード
              AND    xxoh.object_header_id = xxcl.object_header_id      -- 物件内部ID
              AND    xxcl.lease_kind       = cv_zero                    -- リース種類(Fin)
              AND    xxch.contract_header_id = xxcl.contract_header_id  -- 契約内部ID
              ;
            EXCEPTION
              -- 該当データが存在しない場合
              WHEN NO_DATA_FOUND THEN
                NULL;
              -- 抽出に失敗した場合
              WHEN OTHERS THEN
                lv_msg := xxccp_common_pkg.get_msg(
                                iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                               ,iv_name        => cv_tkn_number_69           -- メッセージ
                          );
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_68          -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                               ,iv_token_value1 => lv_msg                    -- トークン値1
                               ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                               ,iv_token_value2 => SQLERRM                   -- トークン値2
                             );
                RAISE chk_target_data_expt;
            END;
            --
            -- リース開始日を取得した場合、償却日を抽出する
            IF ( lt_lease_start_date IS NOT NULL ) THEN
            --
              -- リース開始日から償却日を取得
              BEGIN
                SELECT 
                       ADD_MONTHS( lt_lease_start_date , flvv.attribute1 * 12 ) deprn_date  -- 償却日
                INTO
                       ld_deprn_date
                FROM   fnd_lookup_values_vl flvv
                WHERE  flvv.lookup_type  = cv_lookup_deprn_year
                AND    flvv.enabled_flag = cv_flag_yes
                AND    flvv.attribute2   = lt_lease_class
                AND    flvv.start_date_active <= lt_lease_start_date  -- 有効開始日
                AND    flvv.end_date_active   >= lt_lease_start_date  -- 有効終了日
                ;
              EXCEPTION
                -- 該当データが存在しない場合
                WHEN NO_DATA_FOUND THEN
                  NULL;
                -- 抽出に失敗した場合
                WHEN OTHERS THEN
                  lv_msg := xxccp_common_pkg.get_msg(
                                  iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                                 ,iv_name        => cv_tkn_number_70           -- メッセージ
                            );
                  lv_errbuf := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                                 ,iv_name         => cv_tkn_number_68          -- メッセージコード
                                 ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                                 ,iv_token_value1 => lv_msg                    -- トークン値1
                                 ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                                 ,iv_token_value2 => SQLERRM                   -- トークン値2
                               );
                  RAISE chk_target_data_expt;
              END;
            --
            END IF;
            --
            -- 業務日付がリース開始日以上、かつ償却日未満の場合、チェックエラーとする
            IF ( lt_lease_start_date <= id_process_date ) 
              AND ( id_process_date < ld_deprn_date ) THEN
              --
              lv_end_deprn_date := TO_CHAR(ld_deprn_date - 1, cv_date_fmt);
              lv_errbuf := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_67         -- メッセージコード
                              ,iv_token_name1  => cv_tkn_date              -- トークンコード1
                              ,iv_token_value1 => lv_end_deprn_date        -- トークン値1
                           );
              RAISE chk_deprn_date_expt;
            END IF;
          --
          END IF;
        --
        END IF;
/* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
      END IF;
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
    -- リース区分が「固定資産」の場合
    ELSIF ( iv_lease_kbn = cv_fixed_assets ) THEN
      -- プロファイル値取得（XXCFF:台帳名）
      FND_PROFILE.GET( cv_prfl_fa_books ,lt_fa_book_type_code );
      -- プロファイル値が取得できない場合
      IF ( lt_fa_book_type_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_71          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_prof_name          -- トークンコード1
                       ,iv_token_value1 => cv_prfl_fa_books          -- トークン値1
                     );
        RAISE sql_expt;
      END IF;
      --
      -- リース種別取得
      lt_lease_class := xxcso_util_common_pkg.get_lookup_attribute(
                           cv_lookup_csi_type_code
                          ,iv_instance_type_code
                          ,1
                          ,id_process_date
                        );
      -- リース種別が取得できない場合
      IF ( lt_lease_class IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_76         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_task_nm           -- トークンコード1
                        ,iv_token_value1 => iv_instance_type_code    -- トークン値1
                        ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
                        ,iv_token_value2 => cv_lookup_csi_type_code  -- トークン値2
                     );
        RAISE sql_expt;
      END IF;
      --
      -- 事業供用日取得
      BEGIN
        SELECT fb.date_placed_in_service date_placed_in_service -- 事業供用日
        INTO   lt_date_placed_in_service
        FROM   fa_additions_b            fab -- 資産詳細情報
              ,fa_books                  fb  -- 資産台帳情報
        WHERE  fab.asset_id      = fb.asset_id
        AND    fb.date_ineffective IS NULL
        AND    fb.book_type_code = lt_fa_book_type_code
        AND    fab.tag_number    = iv_install_code
        ;
      EXCEPTION
        -- 該当データが存在しない場合
        WHEN NO_DATA_FOUND THEN
          NULL;
        -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                          iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                         ,iv_name        => cv_tkn_number_70           -- メッセージ
                    );
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_68          -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                         ,iv_token_value1 => lv_msg                    -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                         ,iv_token_value2 => SQLERRM                   -- トークン値2
                       );
          RAISE chk_target_data_expt;
      END;
      --
      -- 事業供用日を取得した場合
      IF ( lt_date_placed_in_service IS NOT NULL ) THEN
        -- 償却日を取得
        BEGIN
          SELECT ADD_MONTHS( lt_date_placed_in_service , flvv.attribute1 * 12 ) deprn_date -- 償却日
          INTO   ld_deprn_date
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type        = cv_lookup_deprn_year
          AND    flvv.enabled_flag       = cv_flag_yes
          AND    flvv.attribute2         = lt_lease_class
          AND    flvv.start_date_active <= lt_date_placed_in_service  -- 有効開始日
          AND    flvv.end_date_active   >= lt_date_placed_in_service  -- 有効終了日
          ;
        EXCEPTION
          -- 該当データが存在しない場合
          WHEN NO_DATA_FOUND THEN
            NULL;
          -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_msg := xxccp_common_pkg.get_msg(
                            iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                           ,iv_name        => cv_tkn_number_70           -- メッセージ
                      );
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_68          -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                           ,iv_token_value1 => lv_msg                    -- トークン値1
                           ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                           ,iv_token_value2 => SQLERRM                   -- トークン値2
                         );
            RAISE chk_target_data_expt;
        END;
        --
        -- 業務日付が事業供用日以上、かつ償却日未満の場合、チェックエラーとする
        IF ( lt_date_placed_in_service <= id_process_date )
          AND ( id_process_date < ld_deprn_date ) THEN
          --
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name                -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_67                        -- メッセージコード
                         ,iv_token_name1  => cv_tkn_date                             -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(ld_deprn_date - 1, cv_date_fmt) -- トークン値1
                       );
          RAISE chk_deprn_date_expt;
        END IF;
      END IF;
    END IF;
    /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
/* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
      WHEN chk_target_data_expt THEN
        -- *** 対象データ抽出例外 ***
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
      --
      WHEN chk_deprn_date_expt THEN
        -- *** 対象データ抽出例外 ***
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
/* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_object_status;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_syozoku_mst
   * Description      : 所属マスタ存在チェック処理(A-11)
   ***********************************************************************************/
  PROCEDURE check_syozoku_mst(
      iv_work_company_code   IN         VARCHAR2    -- 作業会社コード
    , iv_work_location_code  IN         VARCHAR2    -- 事業所コード
    , ov_errbuf              OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode             OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_syozoku_mst';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_lookup_cd_syozoku_mst    CONSTANT VARCHAR2(30) := 'XXCSO1_SYOZOKU_MST';  -- 参照タイプ「所属マスタ」
    cv_enabled_flag_enabled     CONSTANT VARCHAR2(1)  := 'Y';                   -- 参照タイプの有効フラグ「有効」
    --
    -- *** ローカル変数 ***
    ln_cnt_rec    NUMBER;
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 所属マスタ抽出
    -- ========================================
    BEGIN
      SELECT COUNT( flvv.lookup_code )  cnt
      INTO   ln_cnt_rec
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type  = cv_lookup_cd_syozoku_mst
      AND    flvv.lookup_code  = iv_work_company_code || iv_work_location_code
      AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                              AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
      AND    flvv.enabled_flag = cv_enabled_flag_enabled
      ;
      --
      -- 該当データが存在しない場合
      IF ( ln_cnt_rec = 0 ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_30            -- メッセージコード
                       , iv_token_name1  => cv_tkn_wk_company_cd        -- トークンコード1
                       , iv_token_value1 => iv_work_company_code        -- トークン値1
                       , iv_token_name2  => cv_tkn_location_cd          -- トークンコード2
                       , iv_token_value2 => iv_work_location_code       -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_31            -- メッセージコード
                       , iv_token_name1  => cv_tkn_wk_company_cd        -- トークンコード1
                       , iv_token_value1 => iv_work_company_code        -- トークン値1
                       , iv_token_name2  => cv_tkn_location_cd          -- トークンコード2
                       , iv_token_value2 => iv_work_location_code       -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_syozoku_mst;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_cust_mst
   * Description      : 顧客マスタ存在チェック処理(A-12)
   ***********************************************************************************/
  PROCEDURE check_cust_mst(
      iv_account_number   IN         VARCHAR2    -- 顧客コード
/*20090427_yabuki_ST505_517 START*/
    , id_process_date           IN   DATE        -- 業務処理日付
    , iv_install_code           IN   VARCHAR2    -- 設置用物件コード
    , iv_withdraw_install_code  IN   VARCHAR2    -- 引揚用物件コード
    , in_owner_account_id       IN   NUMBER      -- 設置先アカウントID
/*20090427_yabuki_ST505_517 END*/
    , ov_errbuf           OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode          OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_cust_mst';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_party_sts_active    CONSTANT VARCHAR2(1) := 'A';   -- パーティステータス「有効」
    cv_account_sts_active  CONSTANT VARCHAR2(1) := 'A';   -- アカウントステータス「有効」
    /*20090427_yabuki_ST0505_0517 START*/
    cv_acct_site_sts_active   CONSTANT VARCHAR2(1) := 'A';   -- 顧客所在地ステータス「有効」
    cv_party_site_sts_active  CONSTANT VARCHAR2(1) := 'A';   -- パーティサイトステータス「有効」
    /*20090427_yabuki_ST0505_0517 END*/
    cv_cust_sts_approved   CONSTANT VARCHAR2(2) := '30';  -- 顧客ステータス「承認済」
    cv_cust_sts_customer   CONSTANT VARCHAR2(2) := '40';  -- 顧客ステータス「顧客」
    cv_cust_sts_abeyance   CONSTANT VARCHAR2(2) := '50';  -- 顧客ステータス「休止」
    /* 2009.09.10 K.Satomura 0001335対応 START */
    cv_cust_sts_check_off  CONSTANT VARCHAR2(2) := '99';  -- 顧客ステータス「対象外」
    /* 2009.09.10 K.Satomura 0001335対応 END */
    /*20090402_yabuki_ST177 START*/
    cv_cust_sts_sp_aprvd   CONSTANT VARCHAR2(2) := '25';  -- 顧客ステータス「SP承認済」
    /*20090402_yabuki_ST177 END*/
    /*20090427_yabuki_ST0505_0517 START*/
    cv_cust_resources_v    CONSTANT VARCHAR2(30) := '顧客担当営業員情報';
    cv_tkn_val_cust_cd     CONSTANT VARCHAR2(30) := '顧客コード';
    /*20090427_yabuki_ST0505_0517 END*/
    /* 2009.09.10 K.Satomura 0001335対応 START */
    ct_cust_cl_cd_cust     CONSTANT xxcso_cust_acct_sites_v.customer_class_code%TYPE := '10'; -- 顧客区分=顧客
    ct_cust_cl_cd_round    CONSTANT xxcso_cust_acct_sites_v.customer_class_code%TYPE := '15'; -- 顧客区分=巡回
    /* 2009.09.10 K.Satomura 0001335対応 END */
    --
    -- *** ローカル変数 ***
    lv_customer_status    xxcso_cust_accounts_v.customer_status%TYPE;  -- 顧客ステータス
    /*20090427_yabuki_ST0505_0517 START*/
    lt_cust_acct_id       xxcso_cust_accounts_v.cust_account_id%TYPE;  -- アカウントID
    ln_cnt_rec            NUMBER;                                      -- レコード件数
    /*20090427_yabuki_ST0505_0517 END*/
    /* 2009.09.10 K.Satomura 0001335対応 START */
    lt_customer_class_code xxcso_cust_acct_sites_v.customer_class_code%TYPE;
    /* 2009.09.10 K.Satomura 0001335対応 END */
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 顧客マスタ抽出
    -- ========================================
    BEGIN
/*20090427_yabuki_ST505_517 START*/
--      SELECT xcav.customer_status  customer_status
--      INTO   lv_customer_status
--      FROM   xxcso_cust_accounts_v  xcav
--      WHERE  xcav.account_number = iv_account_number
--      AND    xcav.account_status = cv_party_sts_active
--      AND    xcav.party_status   = cv_account_sts_active
--      ;
      SELECT casv.customer_status  customer_status    -- 顧客ステータス
            ,casv.cust_account_id  cust_account_id    -- アカウントID
            /* 2009.09.10 K.Satomura 0001335対応 START */
            ,casv.customer_class_code customer_class_code
            /* 2009.09.10 K.Satomura 0001335対応 END */
      INTO   lv_customer_status
            ,lt_cust_acct_id
            /* 2009.09.10 K.Satomura 0001335対応 START */
            ,lt_customer_class_code
            /* 2009.09.10 K.Satomura 0001335対応 END */
      FROM   xxcso_cust_acct_sites_v  casv    -- 顧客マスタサイトビュー
      WHERE casv.account_number    = iv_account_number
      AND   casv.account_status    = cv_account_sts_active
      AND   casv.acct_site_status  = cv_acct_site_sts_active
      AND   casv.party_status      = cv_party_sts_active
      AND   casv.party_site_status = cv_party_site_sts_active
      ;
/*20090427_yabuki_ST505_517 END*/
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 該当データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_32            -- メッセージコード
                       , iv_token_name1  => cv_tkn_kokyaku              -- トークンコード1
                       , iv_token_value1 => iv_account_number           -- トークン値1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_33            -- メッセージコード
                       , iv_token_name1  => cv_tkn_kokyaku              -- トークンコード1
                       , iv_token_value1 => iv_account_number           -- トークン値1
                       , iv_token_name2  => cv_tkn_err_msg              -- トークンコード2
                       , iv_token_value2 => SQLERRM                     -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    /* 2009.09.10 K.Satomura 0001335対応 START */
    IF (lt_customer_class_code = ct_cust_cl_cd_cust) THEN
    /* 2009.09.10 K.Satomura 0001335対応 END */
      /*20090402_yabuki_ST177 START*/
      -- 取得した顧客ステータスが「承認済」「顧客」「休止」「SP承認済」以外の場合
      IF ( lv_customer_status NOT IN ( cv_cust_sts_approved, cv_cust_sts_customer, cv_cust_sts_abeyance, cv_cust_sts_sp_aprvd ) ) THEN
      ---- 取得した顧客ステータスが「承認済」「顧客」「休止」以外の場合
      --IF ( lv_customer_status NOT IN ( cv_cust_sts_approved, cv_cust_sts_customer, cv_cust_sts_abeyance ) ) THEN
      /*20090402_yabuki_ST177 END*/
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_34            -- メッセージコード
                       , iv_token_name1  => cv_tkn_kokyaku              -- トークンコード1
                       , iv_token_value1 => iv_account_number           -- トークン値1
                       , iv_token_name2  => cv_tkn_cust_status          -- トークンコード2
                       , iv_token_value2 => lv_customer_status          -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    /* 2009.09.10 K.Satomura 0001335対応 START */
    ELSIF (lt_customer_class_code = ct_cust_cl_cd_round) THEN
      -- 顧客区分が15：巡回の場合、顧客ステータスは99以外はエラー
      IF (lv_customer_status <> cv_cust_sts_check_off) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_55            -- メッセージコード
                       , iv_token_name1  => cv_tkn_kokyaku              -- トークンコード1
                       , iv_token_value1 => iv_account_number           -- トークン値1
                       , iv_token_name2  => cv_tkn_cust_status          -- トークンコード2
                       , iv_token_value2 => lv_customer_status          -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    /* 2009.11.25 K.Satomura E_本稼動_00027対応 START */
    ELSE
      -- 上記以外の場合はエラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_34         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kokyaku           -- トークンコード1
                     ,iv_token_value1 => iv_account_number        -- トークン値1
                     ,iv_token_name2  => cv_tkn_cust_status       -- トークンコード2
                     ,iv_token_value2 => lv_customer_status       -- トークン値2
                   );
      --
      RAISE sql_expt;
      --
    /* 2009.11.25 K.Satomura E_本稼動_00027対応 END */
    END IF;
    /* 2009.09.10 K.Satomura 0001335対応 END */
    --
/*20090427_yabuki_ST505_517 START*/
    BEGIN
      SELECT COUNT(1)
      INTO   ln_cnt_rec
      FROM   xxcso_employees_v       empv    -- 従業員マスタビュー
           , xxcso_cust_resources_v  crsv    -- 顧客担当営業員ビュー
      WHERE crsv.account_number    = iv_account_number
      AND   id_process_date
              BETWEEN TRUNC( NVL( crsv.start_date_active, id_process_date ) )
                  AND TRUNC( NVL( crsv.end_date_active, id_process_date ) )
      AND   crsv.employee_number   = empv.employee_number
      AND   id_process_date
              BETWEEN TRUNC( NVL( empv.start_date, id_process_date ) )
                  AND TRUNC( NVL( empv.end_date, id_process_date ) )
      AND   id_process_date
              BETWEEN TRUNC( NVL( empv.employee_start_date, id_process_date ) )
                  AND TRUNC( NVL( empv.employee_end_date, id_process_date ) )
      AND   id_process_date
              BETWEEN TRUNC( NVL( empv.assign_start_date, id_process_date ) )
                  AND TRUNC( NVL( empv.assign_end_date, id_process_date ) )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_49          -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       , iv_token_value1 => cv_cust_resources_v       -- トークン値1
                       , iv_token_name2  => cv_tkn_item               -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_cust_cd        -- トークン値2
                       , iv_token_name3  => cv_tkn_value              -- トークンコード3
                       , iv_token_value3 => iv_account_number         -- トークン値3
                       , iv_token_name4  => cv_tkn_err_msg            -- トークンコード4
                       , iv_token_value4 => SQLERRM                   -- トークン値4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- 該当データが存在しない場合
    IF ( ln_cnt_rec = 0 ) THEN
      /* 2009.08.11 K.Satomura 0000662対応 START */
      SELECT COUNT(1)
      INTO   ln_cnt_rec
      FROM   xxcmm_cust_accounts xca -- 顧客アドオンマスタ
      WHERE  xca.customer_code        = iv_account_number
      AND    xca.cnvs_business_person IS NOT NULL
      ;
      --
      IF (ln_cnt_rec = 0) THEN
      /* 2009.08.11 K.Satomura 0000662対応 END */
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_48          -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm            -- トークンコード1
                       , iv_token_value1 => cv_cust_resources_v       -- トークン値1
                       , iv_token_name2  => cv_tkn_item               -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_cust_cd        -- トークン値2
                       , iv_token_name3  => cv_tkn_value              -- トークンコード3
                       , iv_token_value3 => iv_account_number         -- トークン値3
                     );
        --
        RAISE sql_expt;
        --
      /* 2009.08.11 K.Satomura 0000662対応 START */
      END IF;
      /* 2009.08.11 K.Satomura 0000662対応 END */
    END IF;
    /* 2009.08.11 K.Satomura 0000662対応 END */
    --
    -- 設置用物件コードが設定されている場合
    IF ( iv_install_code IS NOT NULL ) THEN
      -- 設置用物件の設置先アカウントIDと設置先_顧客コードのアカウントIDが異なる場合
      IF ( in_owner_account_id <> lt_cust_acct_id ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_50            -- メッセージコード
                       , iv_token_name1  => cv_tkn_bukken               -- トークンコード1
                       , iv_token_value1 => iv_install_code             -- トークン値1
                       , iv_token_name2  => cv_tkn_kokyaku              -- トークンコード2
                       , iv_token_value2 => iv_account_number           -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    END IF;
    --
    -- 引揚用物件コードが設定されている場合
    IF ( iv_withdraw_install_code IS NOT NULL ) THEN
      -- 設置用物件の設置先アカウントIDと設置先_顧客コードのアカウントIDが異なる場合
      IF ( in_owner_account_id <> lt_cust_acct_id ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_51            -- メッセージコード
                       , iv_token_name1  => cv_tkn_bukken               -- トークンコード1
                       , iv_token_value1 => iv_withdraw_install_code    -- トークン値1
                       , iv_token_name2  => cv_tkn_kokyaku              -- トークンコード2
                       , iv_token_value2 => iv_account_number           -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    END IF;
/*20090427_yabuki_ST505_517 END*/
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_cust_mst;
  --
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
  /**********************************************************************************
   * Procedure Name   : check_dclr_place_mst
   * Description      : 申告地マスタ存在チェック処理(A-27)
   ***********************************************************************************/
  PROCEDURE check_dclr_place_mst(
      iv_declaration_place   IN         VARCHAR2    -- 申告地コード
    , id_process_date        IN         DATE        -- 業務処理日付
    , ov_errbuf              OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode             OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_dclr_place_mst';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_declaration_place_mst    CONSTANT VARCHAR2(30) := 'XXCFF_DCLR_PLACE';  -- 値セット「申告地」
    cv_enabled_flag_enabled     CONSTANT VARCHAR2(1)  := 'Y';                 -- 値セットの有効フラグ「有効」
    --
    -- *** ローカル変数 ***
    lv_msg1       VARCHAR2(5000);  -- ユーザー・メッセージ(ノート)
    lv_msg2       VARCHAR2(5000);  -- ユーザー・メッセージ(ノート)
    ln_cnt        NUMBER;
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 申告地マスタ抽出
    -- ========================================
    BEGIN
      SELECT COUNT(1)             cnt
      INTO   ln_cnt
      FROM   fnd_flex_values      ffv
           , fnd_flex_values_tl   ffvt
           , fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_declaration_place_mst
      AND    id_process_date          BETWEEN TRUNC( NVL( ffv.start_date_active, id_process_date ) )
                                      AND     TRUNC( NVL( ffv.end_date_active,   id_process_date ) )
      AND    ffv.enabled_flag         = cv_enabled_flag_enabled
      AND    ffvt.language            = USERENV('LANG')
      AND    ffv.flex_value           = iv_declaration_place
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_msg2   := xxccp_common_pkg.get_msg(
                           iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                          ,iv_name        => cv_tkn_number_75           -- メッセージ
                     );
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_73            -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                -- トークンコード1
                       , iv_token_value1 => lv_msg2                     -- トークン値1
                       , iv_token_name2  => cv_tkn_err_msg              -- トークンコード2
                       , iv_token_value2 => SQLERRM                     -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- 該当データが存在しない場合
    IF ( ln_cnt = 0 ) THEN
      lv_msg1   := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                        ,iv_name        => cv_tkn_number_74           -- メッセージ
                   );
      lv_msg2   := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name   -- アプリケーション短縮名
                        ,iv_name        => cv_tkn_number_75           -- メッセージ
                   );
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_72            -- メッセージコード
                     , iv_token_name1  => cv_tkn_item                 -- トークンコード1
                     , iv_token_value1 => lv_msg1                     -- トークン値1
                     , iv_token_name2  => cv_tkn_table                -- トークンコード2
                     , iv_token_value2 => lv_msg2                     -- トークン値2
                     , iv_token_name3  => cv_tkn_base_value           -- トークンコード3
                     , iv_token_value3 => iv_declaration_place        -- トークン値3
                   );
      --
      RAISE sql_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_dclr_place_mst;
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
  --
  /**********************************************************************************
   * Procedure Name   : lock_ib_info
   * Description      : 物件ロック処理(A-13)
   ***********************************************************************************/
  PROCEDURE lock_ib_info(
      in_instance_id         IN         csi_item_instances.instance_id%TYPE    -- インスタンスID
    , iv_install_code        IN         VARCHAR2    -- 物件コード
    , iv_lock_err_tkn_num    IN         VARCHAR2    -- ロック失敗時のエラーメッセージ番号
    , iv_others_err_tkn_num  IN         VARCHAR2    -- 抽出失敗時のエラーメッセージ番号
    , ov_errbuf              OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode             OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'lock_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    --
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 物件のロック
    -- ========================================
    BEGIN
      SELECT cii.instance_id  instance_id
      INTO   ln_instance_id
      FROM   csi_item_instances  cii
      WHERE  cii.instance_id = in_instance_id
      FOR UPDATE NOWAIT
      ;
      --
    EXCEPTION
      WHEN g_lock_expt THEN
        -- ロックに失敗した場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => iv_lock_err_tkn_num         -- メッセージコード
                       , iv_token_name1  => cv_tkn_bukken               -- トークンコード1
                       , iv_token_value1 => iv_install_code             -- トークン値1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => iv_others_err_tkn_num       -- メッセージコード
                       , iv_token_name1  => cv_tkn_bukken               -- トークンコード1
                       , iv_token_value1 => iv_install_code             -- トークン値1
                       , iv_token_name2  => cv_tkn_err_msg              -- トークンコード2
                       , iv_token_value2 => SQLERRM                     -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆ロックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END lock_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_ib_info
   * Description      : 設置用物件更新処理(A-14)
   ***********************************************************************************/
  PROCEDURE update_ib_info(
/*20090416_yabuki_ST398 START*/
      iv_process_kbn          IN         VARCHAR2                                -- 処理区分
    , i_instance_rec          IN         g_instance_rtype                        -- 物件情報
--      i_instance_rec          IN         g_instance_rtype                        -- 物件情報
/*20090416_yabuki_ST398 END*/
    , i_requisition_rec       IN         g_requisition_rtype                     -- 発注依頼情報
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- 取引タイプID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- 作業依頼中フラグ「ＯＮ」
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- *** ローカル変数 ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    --
    -- API入力値格納用
    ln_validation_level    NUMBER;
    --
    -- API入出力レコード値格納用
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- 戻り値格納用
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    --------------------------------------------------
    -- 処理区分が「発注依頼承認」の場合
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
      RETURN;
    END IF;
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    -- ========================================
    -- A-13. 物件ロック処理
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_35
      , iv_others_err_tkn_num => cv_tkn_number_36
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- 物件ロック処理が正常終了でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- 処理区分が「発注依頼申請」の場合
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
/*20090416_yabuki_ST398 END*/
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- 処理区分が「発注依頼否認」の場合
    --------------------------------------------------
    ELSE
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
    END IF;
/*20090416_yabuki_ST398 END*/
    --
    ------------------------------
    -- 取引レコード設定
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    ------------------------------
    -- ＩＢ更新用標準API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- APIが正常終了でない場合
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆ロックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- APIでエラーが発生した場合
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                 -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_37                         -- メッセージコード
                     , iv_token_name1  => cv_tkn_bukken                            -- トークンコード1
                     , iv_token_value1 => i_requisition_rec.withdraw_install_code  -- トークン値1
                     , iv_token_name2  => cv_tkn_api_err_msg                       -- トークンコード2
                     , iv_token_value2 => lv_msg_data                              -- トークン値2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END update_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_withdraw_ib_info
   * Description      : 引揚用物件更新処理(A-15)
   ***********************************************************************************/
  PROCEDURE update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
      iv_process_kbn          IN         VARCHAR2                                -- 処理区分
    , i_instance_rec          IN         g_instance_rtype                        -- 物件情報
--      i_instance_rec          IN         g_instance_rtype                        -- 物件情報
/*20090416_yabuki_ST398 END*/
    , i_requisition_rec       IN         g_requisition_rtype                     -- 発注依頼情報
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- 取引タイプID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_withdraw_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- 作業依頼中フラグ「ＯＮ」
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- *** ローカル変数 ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    --
    -- API入力値格納用
    ln_validation_level    NUMBER;
    --
    -- API入出力レコード値格納用
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- 戻り値格納用
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    --------------------------------------------------
    -- 処理区分が「発注依頼承認」の場合
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
      RETURN;
    END IF;
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    -- ========================================
    -- A-13. 物件ロック処理
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.withdraw_install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_38
      , iv_others_err_tkn_num => cv_tkn_number_39
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- 物件ロック処理が正常終了でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- 処理区分が「発注依頼申請」の場合
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
/*20090416_yabuki_ST398 END*/
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- 処理区分が「発注依頼否認」の場合
    --------------------------------------------------
    ELSE
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
    END IF;
/*20090416_yabuki_ST398 END*/
    --
    ------------------------------
    -- 取引レコード設定
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    ------------------------------
    -- ＩＢ更新用標準API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- APIが正常終了でない場合
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆ロックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- APIでエラーが発生した場合
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                 -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_40                         -- メッセージコード
                     , iv_token_name1  => cv_tkn_bukken                            -- トークンコード1
                     , iv_token_value1 => i_requisition_rec.withdraw_install_code  -- トークン値1
                     , iv_token_name2  => cv_tkn_api_err_msg                       -- トークンコード2
                     , iv_token_value2 => lv_msg_data                              -- トークン値2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END update_withdraw_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_abo_appl_ib_info
   * Description      : 廃棄申請用物件更新処理(A-16)
   ***********************************************************************************/
  PROCEDURE update_abo_appl_ib_info(
      iv_process_kbn          IN         VARCHAR2                                -- 処理区分
    , i_instance_rec          IN         g_instance_rtype                        -- 物件情報
    , i_requisition_rec       IN         g_requisition_rtype                     -- 発注依頼情報
    , i_ib_ext_attr_id_rec    IN         g_ib_ext_attr_id_rtype                  -- IB追加属性ID情報
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- 取引タイプID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_abo_appl_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- 作業依頼中フラグ「ＯＮ」
--    cv_op_req_flag_off     CONSTANT VARCHAR2(1)    := 'N';  -- 作業依頼中フラグ「ＯＦＦ」
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- 属性値
    cv_jotai_kbn3_ablsh_appl  CONSTANT VARCHAR2(1) := '2';  -- 機器状態３（廃棄情報）「廃棄申請中」
    cv_ablsh_flg_ablsh_appl   CONSTANT VARCHAR2(1) := '1';  -- 廃棄フラグ「廃棄申請中」
/* 20090511_abe_ST965 START*/
    cv_jotai_kbn3_ablsh_appl_0 CONSTANT VARCHAR2(1) := '0'; -- 機器状態３（廃棄情報）「予定無し」
    cv_ablsh_flg_ablsh_appl_0  CONSTANT VARCHAR2(1) := '0'; -- 廃棄フラグ「未申請」
/* 20090511_abe_ST965 END*/
    --
    -- *** ローカルデータ型 ***
    TYPE l_iea_val_ttype IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- *** ローカル変数 ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    l_iea_val_rec     csi_iea_values%ROWTYPE;
    l_iea_val_tab     l_iea_val_ttype;
/* 20090511_abe_ST965 START*/
    ln_instance_status_id      NUMBER;                  -- インスタンスステータスID
    ln_machinery_status1       NUMBER;                  -- 機器状態1（稼動状態）
    ln_machinery_status2       NUMBER;                  -- 機器状態2（状態詳細）
    ln_machinery_status3       NUMBER;                  -- 機器状態3（廃棄情報）
    ln_delete_flag             NUMBER;                  -- 削除フラグ
/* 20090511_abe_ST965 END*/
    --
    -- API入力値格納用
    ln_validation_level    NUMBER;
    --
    -- API入出力レコード値格納用
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- 戻り値格納用
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
/* 20090511_abe_ST965 START*/
    chk_expt      EXCEPTION;
/* 20090511_abe_ST965 END*/
    
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    --------------------------------------------------
    -- 処理区分が「発注依頼申請」の場合
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
/*20090416_yabuki_ST549 START*/
/* 20090511_abe_ST965 START*/
      ------------------------------
      -- 追加属性値情報取得
      ------------------------------
      -- 機器状態３（廃棄情報）
      l_iea_val_tab(1)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- 属性定義
           );
      --
      -- 廃棄フラグ
      l_iea_val_tab(2)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- 属性定義
           );
      --
      ------------------------------
      -- 追加属性値情報レコード設定
      ------------------------------
      -- 機器状態３（廃棄情報）
      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_appl;
      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
      --
      -- 廃棄フラグ
      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_appl;
        --
      ELSE
        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_appl;
        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
        --
      END IF;
      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- インスタンスステータスID（廃棄手続中）
/* 20090511_abe_ST965 END*/
/*20090416_yabuki_ST549 END*/
      --
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- 処理区分が「発注依頼否認」の場合
    --------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_dngtn ) THEN
/* 20090511_abe_ST965 START*/
      ------------------------------
      -- 追加属性値情報取得
      ------------------------------
      -- 機器状態３（廃棄情報）
      l_iea_val_tab(1)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- 属性定義
           );
      --
      -- 廃棄フラグ
      l_iea_val_tab(2)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- 属性定義
           );
      --
      ------------------------------
      -- 追加属性値情報レコード設定
      ------------------------------
      -- 機器状態３（廃棄情報）
      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_appl_0;
      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
      --
      -- 廃棄フラグ
      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_appl_0;
        --
      ELSE
        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_appl_0;
        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
        --
      END IF;

      ln_machinery_status1  := i_instance_rec.jotai_kbn1;
      ln_machinery_status2  := i_instance_rec.jotai_kbn2;
      ln_machinery_status3  := i_instance_rec.jotai_kbn3;
      ln_delete_flag        := i_instance_rec.delete_flag;
      -- ========================
      -- 2.機器状態整合性チェック
      -- ========================
      -- 削除フラグが「９：論理削除」の場合
      IF (ln_delete_flag = cn_num9) THEN
        ln_instance_status_id := gt_instance_status_id_6;
      -- 機器状態１が「２：滞留」
      -- 機器状態２が「０：情報無」または「１：整備済」
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status2 = cn_num0 OR ln_machinery_status2 = cn_num1))THEN
        ln_instance_status_id := gt_instance_status_id_2;
      -- 機器状態１が「２：滞留」
      -- 機器状態２が「２：整備予定」または「３：保管」または「９：故障中」
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status2 = cn_num2 OR
                      /* 2009.07.14 K.Satomura 統合テスト障害対応(0000476) START */
                      --ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num4)) THEN
                      ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num9)) THEN
                      /* 2009.07.14 K.Satomura 統合テスト障害対応(0000476) END */
        ln_instance_status_id := gt_instance_status_id_3;
      -- 機器状態不正
      ELSE
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_52              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm                -- トークンコード1
                       ,iv_token_value1 => cv_machinery_status           -- トークン値1
                       ,iv_token_name2  => cv_tkn_bukken                 -- トークンコード2
                       ,iv_token_value2 => i_instance_rec.install_code   -- トークン値2
                       ,iv_token_name3  => cv_tkn_hazard_state1          -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(ln_machinery_status1) -- トークン値3
                       ,iv_token_name4  => cv_tkn_hazard_state2          -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(ln_machinery_status2) -- トークン値4
                       ,iv_token_name5  => cv_tkn_hazard_state3          -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(ln_machinery_status3) -- トークン値5
                     );
        RAISE chk_expt;
      END IF; 
      l_instance_rec.instance_status_id     := ln_instance_status_id;    -- インスタンスステータスID
/* 20090511_abe_ST965 END*/
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 END*/
      --
    --------------------------------------------------
    -- 処理区分が「発注依頼承認」の場合
    --------------------------------------------------
    ELSE
/*20090416_yabuki_ST549 START*/
/* 20090511_abe_ST965 START*/
--      ------------------------------
--      -- 追加属性値情報取得
--      ------------------------------
--      -- 機器状態３（廃棄情報）
--      l_iea_val_tab(1)
--        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
--               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
--             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- 属性定義
--           );
--      --
--      -- 廃棄フラグ
--      l_iea_val_tab(2)
--        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
--               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
--             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- 属性定義
--           );
--      --
--      ------------------------------
--      -- 追加属性値情報レコード設定
--      ------------------------------
--      -- 機器状態３（廃棄情報）
--      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
--      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_appl;
--      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
--      --
--      -- 廃棄フラグ
--      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
--        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
--        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
--        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_appl;
--        --
--      ELSE
--        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
--        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_appl;
--        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
--        --
--      END IF;
/* 20090511_abe_ST965 END*/
/*20090416_yabuki_ST549 END*/
      --
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST549 START*/
/* 20090511_abe_ST965 START*/
--      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- インスタンスステータスID（廃棄手続中）
/* 20090511_abe_ST965 END*/
/*20090416_yabuki_ST549 END*/
      --
    END IF;
    --
    ------------------------------
    -- 取引レコード設定
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    -- ========================================
    -- A-13. 物件ロック処理
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.abolishment_install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_41
      , iv_others_err_tkn_num => cv_tkn_number_42
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- 物件ロック処理が正常終了でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
    ------------------------------
    -- ＩＢ更新用標準API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- APIが正常終了でない場合
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆ロックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
/* 20090511_abe_ST965 START*/
    WHEN chk_expt THEN
      -- *** チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
/* 20090511_abe_ST965 END*/
    WHEN api_expt THEN
      -- APIでエラーが発生した場合
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_40                            -- メッセージコード
                     , iv_token_name1  => cv_tkn_bukken                               -- トークンコード1
                     , iv_token_value1 => i_requisition_rec.abolishment_install_code  -- トークン値1
                     , iv_token_name2  => cv_tkn_api_err_msg                          -- トークンコード2
                     , iv_token_value2 => lv_msg_data                                 -- トークン値2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END update_abo_appl_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_abo_aprv_ib_info
   * Description      : 廃棄決裁用物件更新処理(A-17)
   ***********************************************************************************/
  PROCEDURE update_abo_aprv_ib_info(
      iv_process_kbn          IN         VARCHAR2                                -- 処理区分
    , id_process_date         IN         DATE                                    -- 業務処理日付
    , i_instance_rec          IN         g_instance_rtype                        -- 物件情報
    , i_requisition_rec       IN         g_requisition_rtype                     -- 発注依頼情報
    , i_ib_ext_attr_id_rec    IN         g_ib_ext_attr_id_rtype                  -- IB追加属性ID情報
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- 取引タイプID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- エラー・メッセージ --# 固定 #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_abo_aprv_ib_info';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- 作業依頼中フラグ「ＯＮ」
--    cv_op_req_flag_off     CONSTANT VARCHAR2(1)    := 'N';  -- 作業依頼中フラグ「ＯＦＦ」
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- 属性値
    cv_jotai_kbn3_ablsh_desc  CONSTANT VARCHAR2(1) := '3';  -- 機器状態３（廃棄情報）「廃棄決裁済」
    cv_ablsh_flg_ablsh_desc   CONSTANT VARCHAR2(1) := '9';  -- 廃棄フラグ「廃棄決裁済」
    --
    -- *** ローカルデータ型 ***
    TYPE l_iea_val_ttype IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- *** ローカル変数 ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    l_iea_val_rec     csi_iea_values%ROWTYPE;
    l_iea_val_tab     l_iea_val_ttype;
    --
    -- API入力値格納用
    ln_validation_level    NUMBER;
    --
    -- API入出力レコード値格納用
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- 戻り値格納用
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    --------------------------------------------------
    -- 処理区分が「発注依頼申請」の場合
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- 処理区分が「発注依頼否認」の場合
    --------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_dngtn ) THEN
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 END*/
      --
    --------------------------------------------------
    -- 処理区分が「発注依頼承認」の場合
    --------------------------------------------------
    ELSE
     ------------------------------
      -- 追加属性値情報取得
      ------------------------------
      -- 機器状態３（廃棄情報）
      l_iea_val_tab(1)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- 属性定義
           );
      --
      -- 廃棄フラグ
      l_iea_val_tab(2)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- 属性定義
           );
      --
      -- 廃棄決裁日
      l_iea_val_tab(3)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- インスタンスID
             , iv_attribute_code => cv_attr_cd_haikikessai_dt   -- 属性定義
           );
      --
      ------------------------------
      -- 追加属性値情報レコード設定
      ------------------------------
      -- 機器状態３（廃棄情報）
      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_desc;
      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
      --
      -- 廃棄フラグ
      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_desc;
        --
      ELSE
        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_desc;
        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
        --
      END IF;
      --
      -- 廃棄決裁日
      IF ( l_iea_val_tab(3).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(3).attribute_id    := i_ib_ext_attr_id_rec.abolishment_decision_date;
        l_ext_attrib_values_tab(3).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(3).attribute_value := TRUNC( id_process_date );
        --
      ELSE
        l_ext_attrib_values_tab(3).attribute_value_id    := l_iea_val_tab(3).attribute_value_id;
        l_ext_attrib_values_tab(3).attribute_value       := TRUNC( id_process_date );
        l_ext_attrib_values_tab(3).object_version_number := l_iea_val_tab(3).object_version_number;
        --
      END IF;
      --
      ------------------------------
      -- インスタンスレコード設定
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST549 START*/
      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- インスタンスステータスID（廃棄手続中）
/*20090416_yabuki_ST549 END*/
      --
    END IF;
    --
    ------------------------------
    -- 取引レコード設定
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    -- ========================================
    -- A-13. 物件ロック処理
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.abolishment_install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_41
      , iv_others_err_tkn_num => cv_tkn_number_42
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- 物件ロック処理が正常終了でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
    ------------------------------
    -- ＩＢ更新用標準API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- APIが正常終了でない場合
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆ロックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- APIでエラーが発生した場合
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_40                            -- メッセージコード
                     , iv_token_name1  => cv_tkn_bukken                               -- トークンコード1
                     , iv_token_value1 => i_requisition_rec.abolishment_install_code  -- トークン値1
                     , iv_token_name2  => cv_tkn_api_err_msg                          -- トークンコード2
                     , iv_token_value2 => lv_msg_data                                 -- トークン値2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END update_abo_aprv_ib_info;
  --
  --
/*20090406_yabuki_ST101 START*/
  /**********************************************************************************
   * Procedure Name   : chk_wk_req_proc
   * Description      : 作業依頼／発注情報連携対象テーブル存在チェック処理(A-18)
   ***********************************************************************************/
  PROCEDURE chk_wk_req_proc(
      i_requisition_rec  IN         g_requisition_rtype  -- 発注依頼情報
    , on_rec_count       OUT        NUMBER               -- レコード件数（作業依頼／発注情報連携対象テーブル）
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_wk_req_proc';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_val_select_proc    CONSTANT VARCHAR2(100) := '抽出';
    --
    -- *** ローカルデータ型 ***
    --
    -- *** ローカル変数 ***
    ln_rec_count    NUMBER;    -- レコード件数
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 作業依頼／発注情報連携対象テーブル抽出
    -- ========================================
    BEGIN
      SELECT COUNT(1)  cnt
      INTO   ln_rec_count
      FROM   xxcso_wk_requisition_proc  xwrp
      WHERE  xwrp.requisition_line_id = i_requisition_rec.requisition_line_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_45                           -- メッセージコード
                       , iv_token_name1  => cv_tkn_process                             -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_select_proc                     -- トークン値1
                       , iv_token_name2  => cv_tkn_req_num                             -- トークンコード2
                       , iv_token_value2 => i_requisition_rec.requisition_number       -- トークン値2
                       , iv_token_name3  => cv_tkn_req_line_num                        -- トークンコード3
                       , iv_token_value3 => i_requisition_rec.requisition_line_number  -- トークン値3
                       , iv_token_name4  => cv_tkn_err_msg                             -- トークンコード4
                       , iv_token_value4 => SQLERRM                                    -- トークン値4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- レコード件数をOUTパラメータへ設定
    on_rec_count := ln_rec_count;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END chk_wk_req_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : insert_wk_req_proc
   * Description      : 作業依頼／発注情報連携対象テーブル登録処理(A-19)
   ***********************************************************************************/
--  /**********************************************************************************
--   * Procedure Name   : insert_wk_req_proc
--   * Description      : 作業依頼／発注情報連携対象テーブル登録処理(A-18)
--   ***********************************************************************************/
/*20090406_yabuki_ST101 END*/
  PROCEDURE insert_wk_req_proc(
      i_requisition_rec  IN         g_requisition_rtype  -- 発注依頼情報
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'insert_wk_req_proc';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
/*20090406_yabuki_ST101 START*/
--    cv_interface_flg_off    CONSTANT VARCHAR2(1) := 'N';  -- 連携済フラグ「ＯＦＦ」
    -- トークン用定数
    cv_tkn_val_insert_proc    CONSTANT VARCHAR2(100) := '登録';
/*20090406_yabuki_ST101 END*/
    --
    -- *** ローカルデータ型 ***
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    --------------------------------------------------
    -- 作業依頼／発注情報連携対象テーブル登録
    --------------------------------------------------
    BEGIN
      INSERT INTO xxcso_wk_requisition_proc(
          requisition_line_id     -- 発注依頼明細ID
        , requisition_header_id   -- 発注依頼ヘッダID
        , line_num                -- 発注依頼明細番号
        , interface_flag          -- 連携済フラグ
        , interface_date          -- 連携日
        , created_by              -- 作成者
        , creation_date           -- 作成日
        , last_updated_by         -- 最終更新者
        , last_update_date        -- 最終更新日
        , last_update_login       -- 最終更新ログイン
        , request_id              -- 要求ID
        , program_application_id  -- コンカレント・プログラム・アプリケーションID
        , program_id              -- コンカレント・プログラムID
        , program_update_date     -- プログラム更新日
      ) VALUES (
          i_requisition_rec.requisition_line_id      -- 発注依頼明細ID
        , i_requisition_rec.requisition_header_id    -- 発注依頼ヘッダID
        , i_requisition_rec.requisition_line_number  -- 発注依頼明細番号
        , cv_interface_flg_off                       -- 連携済フラグ
        , NULL                                       -- 連携日
        , fnd_global.user_id                         -- 作成者
        , SYSDATE                                    -- 作成日
        , fnd_global.user_id                         -- 最終更新者
        , SYSDATE                                    -- 最終更新日
        , fnd_global.login_id                        -- 最終更新ログイン
        , fnd_global.conc_request_id                 -- 要求ID
        , fnd_global.prog_appl_id                    -- コンカレント・プログラム・アプリケーションID
        , fnd_global.conc_program_id                 -- コンカレント・プログラムID
        , SYSDATE                                    -- プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
/*20090406_yabuki_ST101 START*/
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_45                           -- メッセージコード
                       , iv_token_name1  => cv_tkn_process                             -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_insert_proc                     -- トークン値1
                       , iv_token_name2  => cv_tkn_req_num                             -- トークンコード2
                       , iv_token_value2 => i_requisition_rec.requisition_number       -- トークン値2
                       , iv_token_name3  => cv_tkn_req_line_num                        -- トークンコード3
                       , iv_token_value3 => i_requisition_rec.requisition_line_number  -- トークン値3
                       , iv_token_name4  => cv_tkn_err_msg                             -- トークンコード4
                       , iv_token_value4 => SQLERRM                                    -- トークン値4
                     );
--        lv_errbuf := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name                   -- アプリケーション短縮名
--                       , iv_name         => cv_tkn_number_45                           -- メッセージコード
--                       , iv_token_name1  => cv_tkn_req_num                             -- トークンコード1
--                       , iv_token_value1 => i_requisition_rec.requisition_number       -- トークン値1
--                       , iv_token_name2  => cv_tkn_req_line_num                        -- トークンコード2
--                       , iv_token_value2 => i_requisition_rec.requisition_line_number  -- トークン値2
--                       , iv_token_name3  => cv_tkn_err_msg                             -- トークンコード3
--                       , iv_token_value3 => SQLERRM                                    -- トークン値3
--                     );
/*20090406_yabuki_ST101 END*/
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END insert_wk_req_proc;
  --
  --
/*20090406_yabuki_ST101 START*/
  /**********************************************************************************
   * Procedure Name   : update_wk_req_proc
   * Description      : 作業依頼／発注情報連携対象テーブル更新処理(A-20)
   ***********************************************************************************/
  PROCEDURE update_wk_req_proc(
      i_requisition_rec  IN         g_requisition_rtype  -- 発注依頼情報
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_wk_req_proc';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_val_update_proc    CONSTANT VARCHAR2(100) := '更新';
    --
    -- *** ローカルデータ型 ***
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    --------------------------------------------------
    -- 作業依頼／発注情報連携対象テーブル更新
    --------------------------------------------------
    BEGIN
      UPDATE xxcso_wk_requisition_proc
      SET line_num               = i_requisition_rec.requisition_line_number  -- 発注依頼明細番号
        , interface_flag         = cv_interface_flg_off                       -- 連携済フラグ
        , interface_date         = NULL                                       -- 連携日
        , last_updated_by        = fnd_global.user_id                         -- 最終更新者
        , last_update_date       = SYSDATE                                    -- 最終更新日
        , last_update_login      = fnd_global.login_id                        -- 最終更新ログイン
        , request_id             = fnd_global.conc_request_id                 -- 要求ID
        , program_application_id = fnd_global.prog_appl_id                    -- コンカレント・プログラム・アプリケーションID
        , program_id             = fnd_global.conc_program_id                 -- コンカレント・プログラムID
        , program_update_date    = SYSDATE                                    -- プログラム更新日
      WHERE
          requisition_line_id = i_requisition_rec.requisition_line_id    -- 発注依頼明細ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_45                           -- メッセージコード
                       , iv_token_name1  => cv_tkn_process                             -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_update_proc                     -- トークン値1
                       , iv_token_name2  => cv_tkn_req_num                             -- トークンコード2
                       , iv_token_value2 => i_requisition_rec.requisition_number       -- トークン値2
                       , iv_token_name3  => cv_tkn_req_line_num                        -- トークンコード3
                       , iv_token_value3 => i_requisition_rec.requisition_line_number  -- トークン値3
                       , iv_token_name4  => cv_tkn_err_msg                             -- トークンコード4
                       , iv_token_value4 => SQLERRM                                    -- トークン値4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END update_wk_req_proc;
/*20090406_yabuki_ST101 END*/
  --
/* 20090410_abe_T1_0108 START*/
  /**********************************************************************************
   * Procedure Name   : start_approval_wf_proc
   * Description      : 承認ワークフロー起動(エラー通知)(A-21)
   ***********************************************************************************/
  PROCEDURE start_approval_wf_proc(
      iv_itemtype              IN         VARCHAR2
    , iv_itemkey               IN         VARCHAR2
    , iv_errmsg                IN         VARCHAR2
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- エラー・メッセージ  --# 固定 #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- リターン・コード    --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_approval_wf_proc';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_wf_itemtype              CONSTANT VARCHAR2(30) := 'XXCSO011';
    cv_wf_process               CONSTANT VARCHAR2(30) := 'XXCSO011A01P01';
    cv_wf_pkg_name              CONSTANT VARCHAR2(30) := 'wf_engine';
    cv_wf_createprocess         CONSTANT VARCHAR2(30) := 'createprocess';
    cv_wf_setitemattrtext       CONSTANT VARCHAR2(30) := 'setitemattrtext';
    cv_wf_startprocess          CONSTANT VARCHAR2(30) := 'startprocess';
    cv_wf_itemtype_reqpprv      CONSTANT VARCHAR2(30) := 'REQAPPRV';
    cv_wf_activity_status       CONSTANT VARCHAR2(30) := 'NOTIFIED';
    --
    -- ワークフロー属性名
    cv_wf_xxcso_approver_user_name    CONSTANT VARCHAR2(30) := 'XXCSO_APPROVER_USER_NAME';
    cv_wf_xxcso_ib_chk_errmsg         CONSTANT VARCHAR2(30) := 'XXCSO_IB_CHK_ERRMSG';
    cv_wf_xxcso_notification_id       CONSTANT VARCHAR2(30) := 'XXCSO_APPROVAL_NOTIFICATION_ID';
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    cv_wf_xxcso_ib_chk_subject        CONSTANT VARCHAR2(30) := 'XXCSO_IB_CHK_SUBJECT';
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    --
    cv_wf_approver_user_name          CONSTANT VARCHAR2(30) := 'APPROVER_USER_NAME';
    --
    -- トークン用定数
    --
    -- *** ローカル変数 ***
    lv_itemkey                  VARCHAR2(100);
    lv_token_value              VARCHAR2(60);
    lv_wf_approver_user_name    VARCHAR2(2000);
    ln_approval_s               NUMBER;
    --
    -- *** ローカル例外 ***
    wf_api_others_expt          EXCEPTION;
    --
    PRAGMA EXCEPTION_INIT( wf_api_others_expt, -20002 );
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    SELECT xxcso_approval_s01.NEXTVAL
    INTO   ln_approval_s
    FROM   DUAL;
    lv_itemkey := cv_wf_itemtype
                    || TO_CHAR( SYSDATE, 'YYYYMMDD' )
                    || TO_CHAR(ln_approval_s);

    -- 承認ユーザ名を取得
    lv_wf_approver_user_name := WF_ENGINE.GetItemAttrText(
        itemtype => iv_itemtype
      , itemkey  => iv_itemkey
      , aname    => cv_wf_approver_user_name
      , ignore_notfound => TRUE
    );
    IF (lv_wf_approver_user_name IS NULL) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ==========================
    -- ワークフロープロセス生成
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_createprocess;
    --
    WF_ENGINE.CREATEPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , process  => cv_wf_process
    );
    --
    -- ==========================
    -- ワークフロー属性設定
    -- ==========================
    --
    -- 承認ユーザ
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_xxcso_approver_user_name
      , avalue   => lv_wf_approver_user_name
    );
    --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    -- 件名
    wf_engine.setitemattrtext(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_xxcso_ib_chk_subject
      , avalue   => cv_tkn_subject1 || gv_requisition_number || cv_tkn_subject3
    );
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    -- エラーメッセージ
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_xxcso_ib_chk_errmsg
      , avalue   => iv_errmsg
    );
    --
    -- ==========================
    -- ワークフロープロセス起動
    -- ==========================
    --
    WF_ENGINE.STARTPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
    );
    --
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
     -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END start_approval_wf_proc;
/* 20090410_abe_T1_0108 END*/
/* 20090515_abe_ST669 START*/
  /**********************************************************************************
   * Procedure Name   : VerifyAuthority
   * Description      : 承認者権限（製品）チェック(A-22)
   ***********************************************************************************/
  FUNCTION VerifyAuthority(itemtype VARCHAR2, itemkey VARCHAR2) RETURN VARCHAR2 is

  L_DM_CALL_REC  PO_DOC_MANAGER_PUB.DM_CALL_REC_TYPE;

  x_progress varchar2(200);
  BEGIN


    L_DM_CALL_REC.Action := 'VERIFY_AUTHORITY_CHECK';

    L_DM_CALL_REC.Document_Type    :=  wf_engine.GetItemAttrText (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'DOCUMENT_TYPE');

    L_DM_CALL_REC.Document_Subtype :=  wf_engine.GetItemAttrText (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'DOCUMENT_SUBTYPE');

    L_DM_CALL_REC.Document_Id      :=  wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'DOCUMENT_ID');


    L_DM_CALL_REC.Line_Id          := NULL;
    L_DM_CALL_REC.Shipment_Id      := NULL;
    L_DM_CALL_REC.Distribution_Id  := NULL;
    L_DM_CALL_REC.Employee_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'APPROVER_EMPID');

    L_DM_CALL_REC.New_Document_Status  := NULL;
    L_DM_CALL_REC.Offline_Code     := NULL;

    L_DM_CALL_REC.Note             := NULL;

    L_DM_CALL_REC.Approval_Path_Id := NULL;

    L_DM_CALL_REC.Forward_To_Id    := NULL;

    L_DM_CALL_REC.Action_date    := NULL;

    L_DM_CALL_REC.Override_funds    := NULL;

  -- Below are the output parameters

    L_DM_CALL_REC.Info_Request     := NULL;

    L_DM_CALL_REC.Document_Status  := NULL;

    L_DM_CALL_REC.Online_Report_Id := NULL;

    L_DM_CALL_REC.Return_Code      := NULL;

    L_DM_CALL_REC.Error_Msg        := NULL;

    /* This is the variable that contains the return value from the
    ** call to the DOC MANAGER:
    ** SUCCESS =0,  TIMEOUT=1,  NO MANAGER=2,  OTHER=3
    */
    L_DM_CALL_REC.Return_Value    := NULL;

    /* Call the API that calls the Document manager */

    PO_DOC_MANAGER_PUB.CALL_DOC_MANAGER(L_DM_CALL_REC);


    IF L_DM_CALL_REC.Return_Value = 0 THEN

       IF ( L_DM_CALL_REC.Return_Code is NULL )  THEN

          return('Y');

       ELSE

          return('N');

       END IF;

    ELSE
       return('F');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       return('F');
  END VerifyAuthority;
/* 20090515_abe_ST669 END*/
/*20090701_abe_ST529 START*/
  --
  /**********************************************************************************
   * Procedure Name   : update_po_req_line
   * Description      : 発注依頼明細更新処理(A-23)
   ***********************************************************************************/
  PROCEDURE update_po_req_line(
      i_requisition_rec  IN         g_requisition_rtype  -- 発注依頼情報
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_po_req_line';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_val_update_proc    CONSTANT VARCHAR2(100) := '更新';
    --
    -- *** ローカルデータ型 ***
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    --------------------------------------------------
    -- 発注依頼明細更新処理
    --------------------------------------------------
    BEGIN
      UPDATE po_requisition_lines_all
      SET    transaction_reason_code = i_requisition_rec.un_number
      WHERE  requisition_line_id     = i_requisition_rec.requisition_line_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_53                           -- メッセージコード
                       , iv_token_name1  => cv_tkn_req_num                             -- トークンコード1
                       , iv_token_value1 => i_requisition_rec.requisition_number       -- トークン値1
                       , iv_token_name2  => cv_tkn_req_line_num                        -- トークンコード2
                       , iv_token_value2 => i_requisition_rec.requisition_line_number  -- トークン値2
                       , iv_token_name3  => cv_tkn_err_msg                             -- トークンコード3
                       , iv_token_value3 => SQLERRM                                    -- トークン値3
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END update_po_req_line;
/*20090701_abe_ST529 END*/
  --
/* 20090708_abe_0000464 START*/
  /**********************************************************************************
   * Procedure Name   : check_maker_code
   * Description      : メーカーコードチェック処理(A-24)
   ***********************************************************************************/
  PROCEDURE check_maker_code(
      id_process_date    IN  DATE                       -- 業務処理日付
    , i_requisition_rec  IN  g_requisition_rtype        -- 発注依頼情報
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_maker_code';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_lookup_cd_maker_code    CONSTANT VARCHAR2(30) := 'XXCSO1_PO_CATEGORY_TYPE';  -- 参照タイプ「品目カテゴリ（営業）」
    cv_enabled_flag_enabled     CONSTANT VARCHAR2(1)  := 'Y';                   -- 参照タイプの有効フラグ「有効」
    --
    -- *** ローカル変数 ***
    ln_cnt_rec    NUMBER;
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 品目カテゴリ（営業）抽出
    -- ========================================
    BEGIN
      SELECT COUNT( flvv.lookup_code )  cnt
      INTO   ln_cnt_rec
      FROM   fnd_lookup_values_vl  flvv
            ,mtl_categories_b     mcb
      WHERE  flvv.lookup_type  = cv_lookup_cd_maker_code
      AND    flvv.attribute2   = i_requisition_rec.maker_code
      AND    TRUNC( id_process_date ) BETWEEN TRUNC( NVL( flvv.start_date_active, id_process_date ) )
                              AND     TRUNC( NVL( flvv.end_date_active, id_process_date ) )
      AND    flvv.enabled_flag = cv_enabled_flag_enabled
      AND    flvv.meaning      = mcb.segment1
      AND    mcb.category_id   = i_requisition_rec.category_id
      AND    TRUNC( id_process_date ) BETWEEN TRUNC( NVL( mcb.start_date_active, id_process_date ) )
                              AND     TRUNC( NVL( mcb.end_date_active, id_process_date ) )
      AND    mcb.enabled_flag  = cv_enabled_flag_enabled
      ;
      --
      -- 該当データが存在しない場合
      IF ( ln_cnt_rec = 0 ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_54            -- メッセージコード
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_54            -- メッセージコード
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_maker_code;
  --
/* 20090708_abe_0000464 END*/
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
  --
  /**********************************************************************************
   * Procedure Name   : check_business_low_type
   * Description      : 業態(小分類)チェック処理(A-25)
   ***********************************************************************************/
  PROCEDURE check_business_low_type(
      i_requisition_rec   IN         g_requisition_rtype   -- 発注依頼情報
    , ov_errbuf           OUT NOCOPY VARCHAR2              -- エラー・メッセージ --# 固定 #
    , ov_retcode          OUT NOCOPY VARCHAR2              -- リターン・コード   --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_business_low_type';  -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_party_sts_active       CONSTANT VARCHAR2(1) := 'A';   -- パーティステータス「有効」
    cv_account_sts_active     CONSTANT VARCHAR2(1) := 'A';   -- アカウントステータス「有効」
    cv_acct_site_sts_active   CONSTANT VARCHAR2(1) := 'A';   -- 顧客所在地ステータス「有効」
    cv_party_site_sts_active  CONSTANT VARCHAR2(1) := 'A';   -- パーティサイトステータス「有効」
    --
    ct_cust_cl_cd_cust        CONSTANT xxcso_cust_acct_sites_v.customer_class_code%TYPE := '10'; -- 顧客区分=顧客
    --
    ct_bsns_lwtp_fll_s_sk     CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '24';   -- 24：フルサービス（消化）VD
    ct_bsns_lwtp_fll_s        CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '25';   -- 25：フルサービスVD
    ct_bsns_lwtp_nouhin       CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '26';   -- 26：納品VD
    ct_bsns_lwtp_sk           CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '27';   -- 27：消化VD
    --
    cv_hzrd_cls_jihanki       CONSTANT VARCHAR2(1) := '1';   -- 機器区分（危険度区分） "1:販売機"
    --
    cv_po_un_num              CONSTANT VARCHAR2(100) := '機種マスタの';
    cv_un_num                 CONSTANT VARCHAR2(100) := '機種コード';
    cv_hzrd_cls               CONSTANT VARCHAR2(100) := '機器区分';
    -- *** ローカル変数 ***
    lt_business_low_type      xxcso_cust_acct_sites_v.business_low_type%TYPE;   -- 業態（小分類）
    lt_customer_class_code    xxcso_cust_acct_sites_v.customer_class_code%TYPE; -- 顧客区分
/* 2014.08.29 S.Yamashita E_本稼動_11719対応 START */
--    lv_hazard_class           VARCHAR2(1);                                      -- 機器区分（危険度区分）
    lv_hazard_class           po_hazard_classes_tl.hazard_class%type;           -- 機器区分（危険度区分）
/* 2014.08.29 S.Yamashita E_本稼動_11719対応 end   */
    /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する start */  
    lv_un_number              po_un_numbers_vl.un_number%TYPE; --機種CD
    /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する end */  
    --
    -- *** ローカル例外 ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ========================================
    -- 顧客マスタ抽出
    -- ========================================
    BEGIN
      SELECT casv.business_low_type    business_low_type      -- 業態（小分類）
            ,casv.customer_class_code  customer_class_code    -- 顧客区分コード
      INTO   lt_business_low_type
            ,lt_customer_class_code
      FROM   xxcso_cust_acct_sites_v  casv    -- 顧客マスタサイトビュー
      WHERE casv.account_number    = i_requisition_rec.install_at_customer_code
      AND   casv.account_status    = cv_account_sts_active
      AND   casv.acct_site_status  = cv_acct_site_sts_active
      AND   casv.party_status      = cv_party_sts_active
      AND   casv.party_site_status = cv_party_site_sts_active
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 該当データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_32                            -- メッセージコード
                       , iv_token_name1  => cv_tkn_kokyaku                              -- トークンコード1
                       , iv_token_value1 => i_requisition_rec.install_at_customer_code  -- トークン値1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_33                            -- メッセージコード
                       , iv_token_name1  => cv_tkn_kokyaku                              -- トークンコード1
                       , iv_token_value1 => i_requisition_rec.install_at_customer_code  -- トークン値1
                       , iv_token_name2  => cv_tkn_err_msg                              -- トークンコード2
                       , iv_token_value2 => SQLERRM                                     -- トークン値2
                     );
        --
        RAISE sql_expt;
        --
    END;
    -- ========================================
    -- 機種マスタ抽出
    -- ========================================
    /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する start */ 
    IF i_requisition_rec.category_kbn in (cv_category_kbn_new_install, cv_category_kbn_new_replace) THEN
      --新台設置・新台代替･･･iPro購買依頼の機種CD
      lv_un_number := i_requisition_rec.un_number;
    ELSE
      --旧台設置・旧台代替･･･設置用物件CDから取得した機種CD
      BEGIN
        SELECT  attribute1              --機種CD
        INTO    lv_un_number
        FROM    csi_item_instances cii
        WHERE   cii.external_reference = i_requisition_rec.install_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_un_number := NULL;
      END;
    --
    END IF; 
    /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する end */ 
    
    
    BEGIN
/* 2014.08.29 S.Yamashita E_本稼動_11719対応 START */
--      SELECT SUBSTRB(phcv.hazard_class,1,1)         -- 機器区分（危険度区分）
      SELECT SUBSTRB(phcv.hazard_class,1,INSTRB(phcv.hazard_class,cv_msg_part_only,1,1)-1)         -- 機器区分（危険度区分）
/* 2014.08.29 S.Yamashita E_本稼動_11719対応 END */
      INTO   lv_hazard_class
      FROM   po_un_numbers_vl     punv              -- 国連番号マスタビュー
            ,po_hazard_classes_vl phcv              -- 危険度区分マスタビュー
      /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する start */
      --WHERE  punv.un_number        = i_requisition_rec.un_number
      WHERE  punv.un_number        = lv_un_number
      /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する end */
      AND    punv.hazard_class_id  = phcv.hazard_class_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 該当データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name             -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_48                     -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm                       -- トークンコード1
                       , iv_token_value1 => cv_hzrd_cls                          -- トークン値1
                       , iv_token_name2  => cv_tkn_item                          -- トークンコード2
                       , iv_token_value2 => cv_un_num                            -- トークン値2
                       , iv_token_name3  => cv_tkn_value                         -- トークンコード3
                       /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する start */
                       --, iv_token_value3 => TO_CHAR(i_requisition_rec.un_number) -- トークン値3
                       , iv_token_value3 => lv_un_number -- トークン値3
                       /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する end */
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name             -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_61                     -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm                       -- トークンコード1
                       , iv_token_value1 => cv_po_un_num                         -- トークン値1
                       , iv_token_name2  => cv_tkn_item                          -- トークンコード2
                       , iv_token_value2 => cv_un_num                            -- トークン値2
                       , iv_token_name3  => cv_tkn_base_val                      -- トークンコード3
                       /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する start */
                       --, iv_token_value3 => TO_CHAR(i_requisition_rec.un_number) -- トークン値3
                       , iv_token_value3 => lv_un_number -- トークン値3
                       /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する end */
                       , iv_token_name4  => cv_tkn_err_msg                       -- トークンコード4
                       , iv_token_value4 => SQLERRM                              -- トークン値4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- 顧客の業態小分類が「24：フルサービス（消化）VD」「25：フルサービスVD」「26：納品VD」「27：消化VD 」以外で且つ、
    -- 顧客の顧客区分が「10：顧客」且つ、機器区分（危険度区分）が"1:販売機"の場合はエラー
    IF (  ( lt_business_low_type   NOT IN ( ct_bsns_lwtp_fll_s_sk
                                           ,ct_bsns_lwtp_fll_s
                                           ,ct_bsns_lwtp_nouhin
                                           ,ct_bsns_lwtp_sk ))
      AND ( lt_customer_class_code = ct_cust_cl_cd_cust )
      AND ( lv_hazard_class        = cv_hzrd_cls_jihanki )  ) THEN
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name             -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_62                     -- メッセージコード
                     , iv_token_name1  => cv_tkn_kisyucd                       -- トークンコード1
                     /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する start */
                     --, iv_token_value1 => TO_CHAR(i_requisition_rec.un_number) -- トークン値1
                     , iv_token_value1 => lv_un_number -- トークン値1
                     /* 2010.04.01 maruyama E_本稼動_02133 作業区分によって機種の取得先を変更する end */
                   );
      --
      RAISE sql_expt;
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQLデータ抽出例外＆チェックエラーハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END check_business_low_type;
  --
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
      iv_itemtype            IN         VARCHAR2
    , iv_itemkey             IN         VARCHAR2
    , iv_process_kbn         IN         VARCHAR2  -- 処理区分
    , ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ  --# 固定 #
    , ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード    --# 固定 #
  ) IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'submain'; -- プロシージャ名
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
    cv_inp_chk_prg_name  CONSTANT VARCHAR2(30) := 'input_check';
    --
    -- *** ローカル変数 ***
    lv_requisition_number   po_requisition_headers.segment1%TYPE;    -- 発注依頼番号
    ld_process_date         DATE;                                    -- 業務処理日付
    ln_transaction_type_id  csi_txn_types.transaction_type_id%TYPE;  -- 取引タイプID
    lv_errbuf2              VARCHAR2(5000);                          -- エラー・メッセージ
    lv_retcode2             VARCHAR2(1);                             -- リターン・コード
/*20090403_yabuki_ST297 START*/
    ln_rec_count            NUMBER;                                  -- 抽出件数
/*20090403_yabuki_ST297 END*/
    --
    -- *** ローカル・カーソル ***
    --
    -- *** ローカル・レコード ***
    l_ib_ext_attr_id_rec        g_ib_ext_attr_id_rtype;  -- IB追加属性ID情報
    l_requisition_rec           g_requisition_rtype;     -- 発注依頼情報
    l_instance_rec              g_instance_rtype;        -- 物件情報（設置用）
    l_withdraw_instance_rec     g_instance_rtype;        -- 物件情報（引揚用）
    l_abolishment_instance_rec  g_instance_rtype;        -- 物件情報（廃棄用）
    --
    -- *** ローカル例外 ***
    input_check_expt      EXCEPTION;  -- 入力チェック処理エラーハンドラ
    reg_upd_process_expt  EXCEPTION;  -- 登録・更新処理エラーハンドラ
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
    --
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
        iv_itemtype            => iv_itemtype
      , iv_itemkey             => iv_itemkey
      , iv_process_kbn         => iv_process_kbn          -- 処理区分
      , ov_requisition_number  => lv_requisition_number   -- 発注依頼番号
      , od_process_date        => ld_process_date         -- 業務処理日付
      , on_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
      , o_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec    -- IB追加属性ID情報
      , ov_errbuf              => lv_errbuf               -- エラー・メッセージ --# 固定 #
      , ov_retcode             => lv_retcode              -- リターン・コード   --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-2. 発注依頼情報抽出
    -- ========================================
    get_requisition_info(
        iv_requisition_number => lv_requisition_number  -- 発注依頼番号
      , id_process_date       => ld_process_date        -- 業務処理日付
/*20090403_yabuki_ST297 START*/
      , on_rec_count          => ln_rec_count           -- 抽出件数
/*20090403_yabuki_ST297 END*/
      , o_requisition_rec     => l_requisition_rec      -- 発注依頼情報
      , ov_errbuf             => lv_errbuf              -- エラー・メッセージ  --# 固定 #
      , ov_retcode            => lv_retcode             -- リターン・コード    --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- エラーメッセージ初期化
    lv_errbuf := NULL;
    --
/*20090403_yabuki_ST297 START*/
    --------------------------------------------------
    -- A-2での抽出件数が0件の場合
    --------------------------------------------------
    IF ( ln_rec_count = 0 )  THEN
      -- 以降の処理をスキップします
      RETURN;
      --
    END IF;
--    --------------------------------------------------
--    -- カテゴリ区分がNULL（営業TM以外）の場合
--    --------------------------------------------------
--    IF ( l_requisition_rec.category_kbn IS NULL )  THEN
--      -- 以降の処理をスキップします
--      RETURN;
--      --
--    END IF;
/*20090403_yabuki_ST297 END*/
    --
    -- ========================================
    -- セーブポイント設定
    -- ========================================
    SAVEPOINT save_point;
    --
    ----------------------------------------------------------------------
    -- 処理区分が「発注依頼申請」「発注依頼承認」の場合
    ----------------------------------------------------------------------
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    --IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
    IF ( iv_process_kbn = cv_proc_kbn_req_appl
      OR iv_process_kbn = cv_proc_kbn_req_aprv )
    THEN
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      --------------------------------------------------
      -- カテゴリ区分が「新台設置」の場合
      --------------------------------------------------
      IF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
        /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 START */
        -- ================================================
        -- A-26. アプリケーションソースコードチェック処理
        -- ================================================
        -- アプリケーションソースコードがNULLならばエラー
        IF ( l_requisition_rec.apps_source_code IS NULL ) THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name             -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_66                     -- メッセージコード
                         , iv_token_name1  => cv_tkn_req_num                       -- トークンコード1
                         , iv_token_value1 => l_requisition_rec.requisition_number -- トークン値1
                       );
          RAISE global_process_expt;
        END IF;
        /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 END   */
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 機種コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_01  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 設置先_顧客コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_06  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 作業関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        ------------------------------
        -- 作業会社CDメーカーチェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_11 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        ------------------------------
        -- 引揚先入力不可チェックチェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_12 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
        ------------------------------
        -- 顧客関連情報入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        ------------------------------
        -- 作業会社妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
        ------------------------------
        -- 申告地必須入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_16 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
        /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
        ------------------------------
        -- 売上・担当拠点妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. 所属マスタ存在チェック処理
        -- ========================================
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- 作業会社コード
          , iv_work_location_code => l_requisition_rec.work_location_code  -- 事業所コード
          , ov_errbuf             => lv_errbuf                             -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                            -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-12. 顧客マスタ存在チェック処理
        -- ========================================
        check_cust_mst(
            iv_account_number => l_requisition_rec.install_at_customer_code  -- 顧客コード（設置先_顧客コード）
/*20090427_yabuki_ST505_517 START*/
          , id_process_date          => ld_process_date                      -- 業務処理日付
          , iv_install_code          => NULL                                 -- 設置用物件コード
          , iv_withdraw_install_code => NULL                                 -- 引揚用物件コード
          , in_owner_account_id      => NULL                                 -- 設置先アカウントID
/*20090427_yabuki_ST505_517 END*/
          , ov_errbuf         => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 20090708_abe_0000464 START*/
        -- ========================================
        -- A-24. メーカーコードチェック処理
        -- ========================================
        check_maker_code(
            id_process_date       => ld_process_date      -- 業務処理日付
          , i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
          , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 20090708_abe_0000464 END*/
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
        -- ========================================
        -- A-25. 業態(小分類)チェック処理
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
          , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
        -- ========================================
        -- A-27. 申告地マスタ存在チェック処理
        -- ========================================
        check_dclr_place_mst(
            iv_declaration_place  => l_requisition_rec.declaration_place    -- 申告地
          , id_process_date       => ld_process_date                        -- 業務処理日付
          , ov_errbuf             => lv_errbuf                              -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                             -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
      --------------------------------------------------
      -- カテゴリ区分が「新台代替」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
        /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 START */
        -- ================================================
        -- A-26. アプリケーションソースコードチェック処理
        -- ================================================
        -- アプリケーションソースコードがNULLならばエラー
        IF ( l_requisition_rec.apps_source_code IS NULL ) THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name             -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_66                     -- メッセージコード
                         , iv_token_name1  => cv_tkn_req_num                       -- トークンコード1
                         , iv_token_value1 => l_requisition_rec.requisition_number -- トークン値1
                       );
          RAISE global_process_expt;
        END IF;
        /* 2013.04.04 T.Ishiwata E_本稼動_10321対応 END   */
        --
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 機種コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_01  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date    => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_05  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date    => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 作業関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date    => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        ------------------------------
        -- 作業会社CDメーカーチェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_11 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date    => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
        ------------------------------
        -- 引揚関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_08  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date    => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
        ------------------------------
        -- 顧客関連情報入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date    => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        ------------------------------
        -- 引揚先(搬入先)妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_14 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- 作業会社妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
        ------------------------------
        -- 申告地必須入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_16 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
        /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
        ------------------------------
        -- 売上・担当拠点妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , o_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6. 引揚用物件情報チェック処理
        -- ========================================
        check_withdraw_ib_info(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , i_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                           -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. 所属マスタ存在チェック処理
        -- ========================================
        ----------------------------------------
        -- チェック対象：設置作業会社、事業所
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- 作業会社コード
          , iv_work_location_code => l_requisition_rec.work_location_code  -- 事業所コード
          , ov_errbuf             => lv_errbuf                             -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                            -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- チェック対象：引揚作業会社、事業所
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.withdraw_company_code   -- 引揚会社コード
          , iv_work_location_code => l_requisition_rec.withdraw_location_code  -- 引揚事業所コード
          , ov_errbuf             => lv_errbuf                                 -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                                -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. 顧客マスタ存在チェック処理
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- 顧客コード（設置先_顧客コード）
          , id_process_date          => ld_process_date                             -- 業務処理日付
          , iv_install_code          => NULL                                        -- 設置用物件コード
          , iv_withdraw_install_code => l_requisition_rec.withdraw_install_code     -- 引揚用物件コード
          , in_owner_account_id      => l_withdraw_instance_rec.owner_account_id    -- 設置先アカウントID
          , ov_errbuf                => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode               => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
/* 20090708_abe_0000464 START*/
        -- ========================================
        -- A-24. メーカーコードチェック処理
        -- ========================================
        check_maker_code(
            id_process_date       => ld_process_date      -- 業務処理日付
          , i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
          , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 20090708_abe_0000464 END*/
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 START */
        -- ========================================
        -- A-25. 業態(小分類)チェック処理
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
          , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
        -- ========================================
        -- A-27. 申告地マスタ存在チェック処理
        -- ========================================
        check_dclr_place_mst(
            iv_declaration_place  => l_requisition_rec.declaration_place    -- 申告地
          , id_process_date       => ld_process_date                        -- 業務処理日付
          , ov_errbuf             => lv_errbuf                              -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                             -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
/* 2010.01.25 K.Hosoi E_本稼動_00533,00319対応 END */
        --
        -- ========================================
        -- A-15. 引揚用物件更新処理
        -- ========================================
        update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn           -- 処理区分
          , i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
--            i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec        -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id   -- 取引タイプID
          , ov_errbuf              => lv_errbuf                -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「旧台設置」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_install ) THEN
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 設置用_物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_02  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 設置先_顧客コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_06  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 作業関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        ------------------------------
        -- 引揚先入力不可チェックチェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_12 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
        ------------------------------
        -- 顧客関連情報入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        ------------------------------
        -- 作業会社妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
        /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
        ------------------------------
        -- 売上・担当拠点妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
        --
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , o_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-5. 設置用物件情報チェック処理
        -- ========================================
        check_ib_info(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , i_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                  -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090413_yabuki_ST198 START*/
        -- リース区分が「自社リース」の場合
        IF ( l_instance_rec.lease_kbn = cv_own_company_lease ) THEN
/*20090413_yabuki_ST198 END*/
          -- ========================================
          -- A-10. 物件ステータスチェック処理
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_01           -- チェック区分（チェック対象：設置用物件）
            , iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
            /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
            , id_process_date => ld_process_date                 -- 業務処理日付
            , iv_process_kbn  => iv_process_kbn                  -- 処理区分
            /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
            /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
            , iv_lease_kbn          => l_instance_rec.lease_kbn  -- リース区分
            , iv_instance_type_code => NULL                      -- インスタンスタイプコード
            /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
            , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
            , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
        -- リース区分が「固定資産」の場合
        ELSIF ( l_instance_rec.lease_kbn = cv_fixed_assets ) THEN
          ------------------------------
          -- 申告地必須入力チェック ※物件マスタの情報が必要な為、ここでチェック
          ------------------------------
          input_check(
             iv_chk_kbn        => cv_input_chk_kbn_16 -- チェック区分
            ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
            ,id_process_date   => ld_process_date     -- 業務処理日付
            ,ov_errbuf         => lv_errbuf           -- エラー・メッセージ  --# 固定 #
            ,ov_retcode        => lv_retcode          -- リターン・コード    --# 固定 #
          );
          --
          -- 正常終了でない場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE input_check_expt;
          END IF;
          --
          -- ========================================
          -- A-27. 申告地マスタ存在チェック処理
          -- ========================================
          check_dclr_place_mst(
              iv_declaration_place  => l_requisition_rec.declaration_place    -- 申告地
            , id_process_date       => ld_process_date                        -- 業務処理日付
            , ov_errbuf             => lv_errbuf                              -- エラー・メッセージ  --# 固定 #
            , ov_retcode            => lv_retcode                             -- リターン・コード    --# 固定 #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
/*20090413_yabuki_ST198 START*/
        END IF;
/*20090413_yabuki_ST198 END*/
        --
        -- ========================================
        -- A-11. 所属マスタ存在チェック処理
        -- ========================================
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- 作業会社コード
          , iv_work_location_code => l_requisition_rec.work_location_code  -- 事業所コード
          , ov_errbuf             => lv_errbuf                             -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                            -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-12. 顧客マスタ存在チェック処理
        -- ========================================
        check_cust_mst(
            iv_account_number => l_requisition_rec.install_at_customer_code  -- 顧客コード（設置先_顧客コード）
/*20090427_yabuki_ST505_517 START*/
          , id_process_date          => ld_process_date                      -- 業務処理日付
          , iv_install_code          => NULL                                 -- 設置用物件コード
          , iv_withdraw_install_code => NULL                                 -- 引揚用物件コード
          , in_owner_account_id      => NULL                                 -- 設置先アカウントID
/*20090427_yabuki_ST505_517 END*/
          , ov_errbuf         => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-25. 業態(小分類)チェック処理
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
          , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
        update_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn          -- 処理区分
          , i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
--            i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec       -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
          , ov_errbuf              => lv_errbuf               -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode              -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「旧台代替」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_replace ) THEN
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 設置用_物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_02  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_05  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 作業関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_08  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
        ------------------------------
        -- 顧客関連情報入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        ------------------------------
        -- 引揚先(搬入先)妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_14 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- 作業会社妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
        /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
        ------------------------------
        -- 売上・担当拠点妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
        --
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        ----------------------------------------
        -- チェック対象：設置用物件
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , o_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- チェック対象：引揚用物件
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , o_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-5. 設置用物件情報チェック処理
        -- ========================================
        check_ib_info(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , i_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                  -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6. 引揚用物件情報チェック処理
        -- ========================================
        check_withdraw_ib_info(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , i_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                           -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090413_yabuki_ST198 START*/
        -- リース区分が「自社リース」の場合
        IF ( l_instance_rec.lease_kbn = cv_own_company_lease ) THEN
/*20090413_yabuki_ST198 END*/
          -- ========================================
          -- A-10. 物件ステータスチェック処理
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_01           -- チェック区分（チェック対象：設置用物件）
            , iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
            /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
            , id_process_date => ld_process_date                 -- 業務処理日付
            , iv_process_kbn  => iv_process_kbn                  -- 処理区分
            /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
            /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
            , iv_lease_kbn          => l_instance_rec.lease_kbn  -- リース区分
            , iv_instance_type_code => NULL                      -- インスタンスタイプコード
            /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
            , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
            , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
        -- リース区分が「固定資産」の場合
        ELSIF ( l_instance_rec.lease_kbn = cv_fixed_assets ) THEN
          ------------------------------
          -- 申告地必須入力チェック ※物件マスタ（リース区分）が必要な為、ここでチェック
          ------------------------------
          input_check(
             iv_chk_kbn        => cv_input_chk_kbn_16 -- チェック区分
            ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
            ,id_process_date   => ld_process_date     -- 業務処理日付
            ,ov_errbuf         => lv_errbuf           -- エラー・メッセージ  --# 固定 #
            ,ov_retcode        => lv_retcode          -- リターン・コード    --# 固定 #
          );
          --
          -- 正常終了でない場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE input_check_expt;
          END IF;
          --
          -- ========================================
          -- A-27. 申告地マスタ存在チェック処理
          -- ========================================
          check_dclr_place_mst(
              iv_declaration_place  => l_requisition_rec.declaration_place    -- 申告地
            , id_process_date       => ld_process_date                        -- 業務処理日付
            , ov_errbuf             => lv_errbuf                              -- エラー・メッセージ  --# 固定 #
            , ov_retcode            => lv_retcode                             -- リターン・コード    --# 固定 #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
/*20090413_yabuki_ST198 START*/
        END IF;
/*20090413_yabuki_ST198 END*/
        --
        -- ========================================
        -- A-11. 所属マスタ存在チェック処理
        -- ========================================
        ----------------------------------------
        -- チェック対象：設置作業会社、事業所
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- 作業会社コード
          , iv_work_location_code => l_requisition_rec.work_location_code  -- 事業所コード
          , ov_errbuf             => lv_errbuf                             -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                            -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- チェック対象：引揚作業会社、事業所
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.withdraw_company_code   -- 引揚会社コード
          , iv_work_location_code => l_requisition_rec.withdraw_location_code  -- 引揚事業所コード
          , ov_errbuf             => lv_errbuf                                 -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                                -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. 顧客マスタ存在チェック処理
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- 顧客コード（設置先_顧客コード）
          , id_process_date          => ld_process_date                             -- 業務処理日付
          , iv_install_code          => NULL                                        -- 設置用物件コード
          , iv_withdraw_install_code => l_requisition_rec.withdraw_install_code     -- 引揚用物件コード
          , in_owner_account_id      => l_withdraw_instance_rec.owner_account_id    -- 設置先アカウントID
          , ov_errbuf                => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode               => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        -- ========================================
        -- A-25. 業態(小分類)チェック処理
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
          , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        --
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
        update_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn          -- 処理区分
          , i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
--            i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec       -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
          , ov_errbuf              => lv_errbuf               -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode              -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. 引揚用物件更新処理
        -- ========================================
        update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn           -- 処理区分
          , i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
--            i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec        -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id   -- 取引タイプID
          , ov_errbuf              => lv_errbuf                -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「引揚」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_withdraw ) THEN
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 設置用_物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_03  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_05  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚関連情報入力チェック
        ------------------------------
        input_check(
/*20090413_yabuki_ST170_171 START*/
            iv_chk_kbn        => cv_input_chk_kbn_10  -- チェック区分
--            iv_chk_kbn        => cv_input_chk_kbn_08  -- チェック区分
/*20090413_yabuki_ST170_171 END*/
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
        ------------------------------
        -- 顧客関連情報入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        ------------------------------
        -- 引揚先(搬入先)妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_14 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- 作業会社妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
        /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
        ------------------------------
        -- 売上・担当拠点妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
        --
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , o_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6. 引揚用物件情報チェック処理
        -- ========================================
        check_withdraw_ib_info(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , i_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                           -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. 所属マスタ存在チェック処理
        -- ========================================
/*20090413_yabuki_ST527 START*/
         /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
         -- 引揚時も作業会社は指定する必要があるためチェックを復活させる
        ----------------------------------------
        -- チェック対象：設置作業会社、事業所
        ----------------------------------------
        check_syozoku_mst(
           iv_work_company_code  => l_requisition_rec.work_company_code  -- 作業会社コード
          ,iv_work_location_code => l_requisition_rec.work_location_code -- 事業所コード
          ,ov_errbuf             => lv_errbuf                            -- エラー・メッセージ  --# 固定 #
          ,ov_retcode            => lv_retcode                           -- リターン・コード    --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
          --
        END IF;
         /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
/*20090413_yabuki_ST527 END*/
        --
        ----------------------------------------
        -- チェック対象：引揚作業会社、事業所
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.withdraw_company_code   -- 引揚会社コード
          , iv_work_location_code => l_requisition_rec.withdraw_location_code  -- 引揚事業所コード
          , ov_errbuf             => lv_errbuf                                 -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                                -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. 顧客マスタ存在チェック処理
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- 顧客コード（設置先_顧客コード）
          , id_process_date          => ld_process_date                             -- 業務処理日付
          , iv_install_code          => NULL                                        -- 設置用物件コード
          , iv_withdraw_install_code => l_requisition_rec.withdraw_install_code     -- 引揚用物件コード
          , in_owner_account_id      => l_withdraw_instance_rec.owner_account_id    -- 設置先アカウントID
          , ov_errbuf                => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode               => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        --
        -- ========================================
        -- A-15. 引揚用物件更新処理
        -- ========================================
        update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn           -- 処理区分
          , i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
--            i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec        -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id   -- 取引タイプID
          , ov_errbuf              => lv_errbuf                -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「廃棄申請」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 設置用_物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_03  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- 引揚用物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 廃棄_物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_09  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
          , o_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
          , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-7. 廃棄申請用物件情報チェック処理
        -- ========================================
        check_ablsh_appl_ib_info(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
          , i_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                              -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-16. 廃棄申請用物件更新処理
        -- ========================================
        update_abo_appl_ib_info(
            iv_process_kbn         => iv_process_kbn              -- 処理区分
          , i_instance_rec         => l_abolishment_instance_rec  -- 物件情報（廃棄用）
          , i_requisition_rec      => l_requisition_rec           -- 発注依頼情報
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB追加属性ID情報
          , in_transaction_type_id => ln_transaction_type_id      -- 取引タイプID
          , ov_errbuf              => lv_errbuf                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「廃棄決裁」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 設置用_物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_03  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 廃棄_物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_09  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
          , o_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
          , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-8. 廃棄決裁用物件情報チェック処理
        -- ========================================
        check_ablsh_aprv_ib_info(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
          , i_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                              -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
--          /* 2013.12.05 T.Nakano E_本稼動_11082対応 START */
--          , id_process_date => ld_process_date                             -- 業務処理日付
--          /* 2013.12.05 T.Nakano E_本稼動_11082対応 END */
          /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
          , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
--/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
--        -- リース区分が「自社リース」の場合
--        IF ( l_abolishment_instance_rec.lease_kbn = cv_own_company_lease ) THEN
--/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
        -- リース区分が「自社リース」、「固定資産」の場合
        IF ( l_abolishment_instance_rec.lease_kbn IN ( cv_own_company_lease, cv_fixed_assets ) ) THEN
/* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
          -- ========================================
          -- A-10. 物件ステータスチェック処理
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_02                       -- チェック区分（チェック対象：廃棄用物件）
            , iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
            /* 2014.04.30 T.Nakano E_本稼動_11770対応 START */
            , id_process_date => ld_process_date                             -- 業務処理日付
            , iv_process_kbn  => iv_process_kbn                              -- 処理区分
            /* 2014.04.30 T.Nakano E_本稼動_11770対応 END */
            /* 2014-05-13 K.Nakamura E_本稼動_11853対応 START */
            , iv_lease_kbn          => l_abolishment_instance_rec.lease_kbn          -- リース区分
            , iv_instance_type_code => l_abolishment_instance_rec.instance_type_code -- インスタンスタイプコード
            /* 2014-05-13 K.Nakamura E_本稼動_11853対応 END */
            , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
            , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) START */
        END IF;
/* 2009.07.16 K.Hosoi 統合テスト障害対応(0000375,0000419) END */
        --
        -- ========================================
        -- A-17. 廃棄決裁用物件更新処理
        -- ========================================
        update_abo_aprv_ib_info(
            iv_process_kbn         => iv_process_kbn              -- 処理区分
          , id_process_date        => ld_process_date             -- 業務処理日付
          , i_instance_rec         => l_abolishment_instance_rec  -- 物件情報（廃棄用）
          , i_requisition_rec      => l_requisition_rec           -- 発注依頼情報
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB追加属性ID情報
          , in_transaction_type_id => ln_transaction_type_id      -- 取引タイプID
          , ov_errbuf              => lv_errbuf                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「店内移動」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_mvmt_in_shp ) THEN
        -- ========================================
        -- A-3. 入力チェック処理
        -- ========================================
        ------------------------------
        -- 設置用_物件コード必須入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_02  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 引揚用物件コード入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- 作業関連情報入力チェック
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- チェック区分
          , i_requisition_rec => l_requisition_rec    -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          , id_process_date   => ld_process_date      -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          , ov_errbuf         => lv_errbuf2           -- エラー・メッセージ  --# 固定 #
          , ov_retcode        => lv_retcode2          -- リターン・コード    --# 固定 #
        );
        -- 正常終了でない場合
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 START */
        ------------------------------
        -- 引揚先入力不可チェックチェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_12 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_本稼動_00119対応 END */
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 START */
        ------------------------------
        -- 顧客関連情報入力チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
          ,id_process_date   => ld_process_date     -- 業務処理日付
          /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_本稼動_00563対応 END */
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 START */
        ------------------------------
        -- 作業会社妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_本稼動_01838,01839対応 END */
        /* 2015-01-13 T.Sano E_本稼動_12289対応 START */
        ------------------------------
        -- 売上・担当拠点妥当性チェック
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- チェック区分
          ,i_requisition_rec => l_requisition_rec   -- 発注依頼情報
          ,id_process_date   => ld_process_date     -- 業務処理日付
          ,ov_errbuf         => lv_errbuf2          -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode2         -- リターン・コード    --# 固定 #
        );
        --
        -- 正常終了でない場合
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- 異常終了の場合
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_本稼動_12289対応 END */
        --
        -- 入力チェック処理が警告終了（チェックエラーあり）の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- リターンコードに「異常」を設定
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , o_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-9. 店内移動用物件情報チェック処理
        -- ========================================
        check_mvmt_in_shp_ib_info(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , i_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
          , iv_process_kbn  => iv_process_kbn                  -- 処理区分
          /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. 所属マスタ存在チェック処理
        -- ========================================
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- 作業会社コード
          , iv_work_location_code => l_requisition_rec.work_location_code  -- 事業所コード
          , ov_errbuf             => lv_errbuf                             -- エラー・メッセージ  --# 固定 #
          , ov_retcode            => lv_retcode                            -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. 顧客マスタ存在チェック処理
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- 顧客コード（設置先_顧客コード）
          , id_process_date          => ld_process_date                             -- 業務処理日付
          , iv_install_code          => l_requisition_rec.install_code              -- 設置用物件コード
          , iv_withdraw_install_code => NULL                                        -- 引揚用物件コード
          , in_owner_account_id      => l_instance_rec.owner_account_id             -- 設置先アカウントID
          , ov_errbuf                => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode               => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        --
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
        update_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn          -- 処理区分
          , i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
--            i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec       -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
          , ov_errbuf              => lv_errbuf               -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode              -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
      --
      /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
      IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
        -- 処理区分が「発注依頼承認」の場合
        -- ========================================
        -- A-18. 作業依頼／発注情報連携対象テーブル存在チェック処理
        -- ========================================
        chk_wk_req_proc(
           i_requisition_rec => l_requisition_rec -- 発注依頼情報
          ,on_rec_count      => ln_rec_count      -- レコード件数（作業依頼／発注情報連携対象テーブル）
          ,ov_errbuf         => lv_errbuf         -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode        -- リターン・コード    --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
        -- 作業依頼／発注情報連携対象テーブルに該当するレコードが存在しない場合
        IF (ln_rec_count = cn_zero) THEN
          -- ========================================
          -- A-19. 作業依頼／発注情報連携対象テーブル登録処理
          -- ========================================
          insert_wk_req_proc(
             i_requisition_rec => l_requisition_rec -- 発注依頼情報
            ,ov_errbuf         => lv_errbuf         -- エラー・メッセージ  --# 固定 #
            ,ov_retcode        => lv_retcode        -- リターン・コード    --# 固定 #
          );
          --
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE reg_upd_process_expt;
            --
          END IF;
          --
        ELSE
          -- ========================================
          -- A-20. 作業依頼／発注情報連携対象テーブル更新処理
          -- ========================================
          update_wk_req_proc(
             i_requisition_rec => l_requisition_rec -- 発注依頼情報
            ,ov_errbuf         => lv_errbuf         -- エラー・メッセージ  --# 固定 #
            ,ov_retcode        => lv_retcode        -- リターン・コード    --# 固定 #
          );
          --
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE reg_upd_process_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ========================================
        -- A-23. 発注依頼明細更新処理
        -- ========================================
        update_po_req_line(
           i_requisition_rec => l_requisition_rec -- 発注依頼情報
          ,ov_errbuf         => lv_errbuf         -- エラー・メッセージ  --# 固定 #
          ,ov_retcode        => lv_retcode        -- リターン・コード    --# 固定 #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
      --
      /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    ----------------------------------------------------------------------
    -- 処理区分が「発注依頼承認」の場合
    ----------------------------------------------------------------------
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    --ELSIF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
    --  --------------------------------------------------
    --  -- カテゴリ区分が「廃棄申請」の場合
    --  --------------------------------------------------
    --  IF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
    --    -- ========================================
    --    -- A-4. 物件マスタ存在チェック処理
    --    -- ========================================
    --    check_ib_existence(
    --        iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
    --      , o_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
    --      , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --    -- ========================================
    --    -- A-16. 廃棄申請用物件更新処理
    --    -- ========================================
    --    update_abo_appl_ib_info(
    --        iv_process_kbn         => iv_process_kbn              -- 処理区分
    --      , i_instance_rec         => l_abolishment_instance_rec  -- 物件情報（廃棄用）
    --      , i_requisition_rec      => l_requisition_rec           -- 発注依頼情報
    --      , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB追加属性ID情報
    --      , in_transaction_type_id => ln_transaction_type_id      -- 取引タイプID
    --      , ov_errbuf              => lv_errbuf                   -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode             => lv_retcode                  -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --  --------------------------------------------------
    --  -- カテゴリ区分が「廃棄決裁」の場合
    --  --------------------------------------------------
    --  ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
    --    --
    --    -- ========================================
    --    -- A-4. 物件マスタ存在チェック処理
    --    -- ========================================
    --    check_ib_existence(
    --        iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
    --      , o_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
    --      , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --    -- ========================================
    --    -- A-17. 廃棄決裁用物件更新処理
    --    -- ========================================
    --    update_abo_aprv_ib_info(
    --        iv_process_kbn         => iv_process_kbn              -- 処理区分
    --      , id_process_date        => ld_process_date             -- 業務処理日付
    --      , i_instance_rec         => l_abolishment_instance_rec  -- 物件情報（廃棄用）
    --      , i_requisition_rec      => l_requisition_rec           -- 発注依頼情報
    --      , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB追加属性ID情報
    --      , in_transaction_type_id => ln_transaction_type_id      -- 取引タイプID
    --      , ov_errbuf              => lv_errbuf                   -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode             => lv_retcode                  -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --  /* 20090708_abe_0000464 START*/
    --  --------------------------------------------------
    --  -- カテゴリ区分が「新台設置」の場合
    --  --------------------------------------------------
    --  ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
    --    -- ========================================
    --    -- A-24. メーカーコードチェック処理
    --    -- ========================================
    --    check_maker_code(
    --        id_process_date       => ld_process_date      -- 業務処理日付
    --      , i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
    --      , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --  --------------------------------------------------
    --  -- カテゴリ区分が「新台代替」の場合
    --  --------------------------------------------------
    --  ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
    --    -- ========================================
    --    -- A-24. メーカーコードチェック処理
    --    -- ========================================
    --    check_maker_code(
    --        id_process_date       => ld_process_date      -- 業務処理日付
    --      , i_requisition_rec     => l_requisition_rec    -- 発注依頼情報
    --      , ov_errbuf             => lv_errbuf            -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode            => lv_retcode           -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --  /* 20090708_abe_0000464 END*/
    --  END IF;
    --  --
    --  /*20090406_yabuki_ST101 START*/
    --  -- ========================================
    --  -- A-18. 作業依頼／発注情報連携対象テーブル存在チェック処理
    --  -- ========================================
    --  chk_wk_req_proc(
    --      i_requisition_rec => l_requisition_rec  -- 発注依頼情報
    --    , on_rec_count      => ln_rec_count       -- レコード件数（作業依頼／発注情報連携対象テーブル）
    --    , ov_errbuf         => lv_errbuf          -- エラー・メッセージ  --# 固定 #
    --    , ov_retcode        => lv_retcode         -- リターン・コード    --# 固定 #
    --  );
    --  --
    --  IF ( lv_retcode <> cv_status_normal ) THEN
    --    RAISE reg_upd_process_expt;
    --    --
    --  END IF;
    --  --
    --  -- 作業依頼／発注情報連携対象テーブルに該当するレコードが存在しない場合
    --  IF ( ln_rec_count = cn_zero ) THEN
    --    -- ========================================
    --    -- A-19. 作業依頼／発注情報連携対象テーブル登録処理
    --    -- ========================================
--  --      -- ========================================
--  --      -- A-18. 作業依頼／発注情報連携対象テーブル登録処理
--  --      -- ========================================
    --    /*20090406_yabuki_ST101 END*/
    --    insert_wk_req_proc(
    --        i_requisition_rec => l_requisition_rec  -- 発注依頼情報
    --      , ov_errbuf         => lv_errbuf          -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode        => lv_retcode         -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --    /*20090406_yabuki_ST101 START*/
    --  ELSE
    --    -- ========================================
    --    -- A-20. 作業依頼／発注情報連携対象テーブル更新処理
    --    -- ========================================
    --    update_wk_req_proc(
    --        i_requisition_rec => l_requisition_rec  -- 発注依頼情報
    --      , ov_errbuf         => lv_errbuf          -- エラー・メッセージ  --# 固定 #
    --      , ov_retcode        => lv_retcode         -- リターン・コード    --# 固定 #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --  END IF;
    --  --
    --  /*20090406_yabuki_ST101 END*/
    --  /* 20090701_abe_ST529 START*/
    --  -- ========================================
    --  -- A-23. 発注依頼明細更新処理
    --  -- ========================================
    --  update_po_req_line(
    --      i_requisition_rec => l_requisition_rec  -- 発注依頼情報
    --    , ov_errbuf         => lv_errbuf          -- エラー・メッセージ  --# 固定 #
    --    , ov_retcode        => lv_retcode         -- リターン・コード    --# 固定 #
    --  );
    --  --
    --  IF ( lv_retcode <> cv_status_normal ) THEN
    --    RAISE reg_upd_process_expt;
    --    --
    --  END IF;
    --  --
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    /* 20090701_abe_ST529 END*/
      --
    /*20090416_yabuki_ST398 START*/
    ----------------------------------------------------------------------
    -- 処理区分が「発注依頼否認」の場合
    ----------------------------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_dngtn ) THEN
      --------------------------------------------------
      -- カテゴリ区分が「新台設置」の場合
      --------------------------------------------------
      IF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
        NULL;
        --
      --------------------------------------------------
      -- カテゴリ区分が「新台代替」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , o_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. 引揚用物件更新処理
        -- ========================================
        update_withdraw_ib_info(
            iv_process_kbn         => iv_process_kbn           -- 処理区分
          , i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
          , i_requisition_rec      => l_requisition_rec        -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id   -- 取引タイプID
          , ov_errbuf              => lv_errbuf                -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「旧台設置」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_install ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , o_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
        update_ib_info(
            iv_process_kbn         => iv_process_kbn          -- 処理区分
          , i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
          , i_requisition_rec      => l_requisition_rec       -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
          , ov_errbuf              => lv_errbuf               -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode              -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「旧台代替」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_replace ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        ----------------------------------------
        -- チェック対象：設置用物件
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , o_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- チェック対象：引揚用物件
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , o_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
        update_ib_info(
            iv_process_kbn         => iv_process_kbn          -- 処理区分
          , i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
          , i_requisition_rec      => l_requisition_rec       -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
          , ov_errbuf              => lv_errbuf               -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode              -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. 引揚用物件更新処理
        -- ========================================
        update_withdraw_ib_info(
            iv_process_kbn         => iv_process_kbn           -- 処理区分
          , i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
          , i_requisition_rec      => l_requisition_rec        -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id   -- 取引タイプID
          , ov_errbuf              => lv_errbuf                -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「引揚」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_withdraw ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- 引揚用物件コード
          , o_instance_rec  => l_withdraw_instance_rec                  -- 物件情報（引揚用）
          , ov_errbuf       => lv_errbuf                                -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. 引揚用物件更新処理
        -- ========================================
        update_withdraw_ib_info(
            iv_process_kbn         => iv_process_kbn           -- 処理区分
          , i_instance_rec         => l_withdraw_instance_rec  -- 物件情報（引揚用）
          , i_requisition_rec      => l_requisition_rec        -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id   -- 取引タイプID
          , ov_errbuf              => lv_errbuf                -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode               -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「廃棄申請」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
          , o_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
          , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-16. 廃棄申請用物件更新処理
        -- ========================================
        update_abo_appl_ib_info(
            iv_process_kbn         => iv_process_kbn              -- 処理区分
          , i_instance_rec         => l_abolishment_instance_rec  -- 物件情報（廃棄用）
          , i_requisition_rec      => l_requisition_rec           -- 発注依頼情報
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB追加属性ID情報
          , in_transaction_type_id => ln_transaction_type_id      -- 取引タイプID
          , ov_errbuf              => lv_errbuf                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「廃棄決裁」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- 廃棄_物件コード
          , o_instance_rec  => l_abolishment_instance_rec                  -- 物件情報（廃棄用）
          , ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-17. 廃棄決裁用物件更新処理
        -- ========================================
        update_abo_aprv_ib_info(
            iv_process_kbn         => iv_process_kbn              -- 処理区分
          , id_process_date        => ld_process_date             -- 業務処理日付
          , i_instance_rec         => l_abolishment_instance_rec  -- 物件情報（廃棄用）
          , i_requisition_rec      => l_requisition_rec           -- 発注依頼情報
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB追加属性ID情報
          , in_transaction_type_id => ln_transaction_type_id      -- 取引タイプID
          , ov_errbuf              => lv_errbuf                   -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode                  -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- カテゴリ区分が「店内移動」の場合
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_mvmt_in_shp ) THEN
        -- ========================================
        -- A-4. 物件マスタ存在チェック処理
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- 設置用物件コード
          , o_instance_rec  => l_instance_rec                  -- 物件情報（設置用）
          , ov_errbuf       => lv_errbuf                       -- エラー・メッセージ  --# 固定 #
          , ov_retcode      => lv_retcode                      -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
        update_ib_info(
            iv_process_kbn         => iv_process_kbn          -- 処理区分
          , i_instance_rec         => l_instance_rec          -- 物件情報（設置用）
          , i_requisition_rec      => l_requisition_rec       -- 発注依頼情報
          , in_transaction_type_id => ln_transaction_type_id  -- 取引タイプID
          , ov_errbuf              => lv_errbuf               -- エラー・メッセージ  --# 固定 #
          , ov_retcode             => lv_retcode              -- リターン・コード    --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
/*20090416_yabuki_ST398 END*/
    END IF;
    --
  EXCEPTION
    --
    WHEN input_check_expt THEN
      -- *** 入力チェック処理エラーハンドラ ***
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_inp_chk_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN reg_upd_process_expt THEN
      -- *** 登録・更新処理エラーハンドラ ***
      ROLLBACK TO save_point;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** 処理部共通例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    --
    --#####################################  固定部 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main_for_application
   * Description      : メイン処理（発注依頼申請用）
   **********************************************************************************/
  --
  PROCEDURE main_for_application(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  )
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'main_for_application';  -- プログラム名
    cv_ib_chk_errmsg  CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_ERRMSG';
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
    cv_ib_chk_subject CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_SUBJECT';
    /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    --
  BEGIN
    --
        -- ========================================
        -- A-13. 設置用物件更新処理
        -- ========================================
    submain(
        iv_itemtype    => itemtype
      , iv_itemkey     => itemkey
      , iv_process_kbn => cv_proc_kbn_req_appl  -- 処理区分（発注依頼申請）
      , ov_errbuf      => lv_errbuf             -- エラー・メッセージ  --# 固定 #
      , ov_retcode     => lv_retcode            -- リターン・コード    --# 固定 #
    );
    --
    -- submainが正常終了の場合
    IF lv_retcode = cv_status_normal THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_yes;
      --
    -- submainが異常終了の場合
    ELSIF lv_retcode = cv_status_error THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      --
      /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_subject
        , avalue   => cv_tkn_subject1 || gv_requisition_number || cv_tkn_subject2
      );
      /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */

      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      --
      /* 2009.12.09 K.Satomura E_本稼動_00341対応 START */
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_subject
        , avalue   => cv_tkn_subject1 || gv_requisition_number || cv_tkn_subject2
      );
      /* 2009.12.09 K.Satomura E_本稼動_00341対応 END */
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
  END main_for_application;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main_for_approval
   * Description      : メイン処理（発注依頼承認用）
   **********************************************************************************/
  --
  PROCEDURE main_for_approval(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  )
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'main_for_approval';  -- プログラム名
    cv_ib_chk_errmsg  CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_ERRMSG';
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    /* 20090410_abe_T1_0108 START*/
    lv_errbuf_wf      VARCHAR2(5000);  -- エラー・メッセージ
    ln_notification_id NUMBER;
    /* 20090410_abe_T1_0108 END*/
    /* 20090515_abe_ST669 START*/
    lv_proc_kbn_req_aprv    VARCHAR2(1);  --処理区分（2:承認、3:否認）
    lv_doc_mgr_return_val   VARCHAR2(1);
    /* 20090515_abe_ST669 END*/
    --
  BEGIN
    --
    /* 20090410_abe_T1_0108 START*/
    -- 複数回起動されるため、通知IDが取得できない場合は終了する。
    BEGIN
      SELECT wias.notification_id
      INTO   ln_notification_id
      FROM   wf_item_activity_statuses wias
      WHERE  wias.item_type = itemtype
      AND    wias.item_key  = itemkey
      AND    wias.notification_id IS NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --

/* 20090515_abe_ST669 START*/
    -- ========================================
    -- A-22. 承認者権限（製品）チェック
    -- ========================================
    lv_doc_mgr_return_val := VerifyAuthority(
                                 itemtype    => itemtype
                               , itemkey     => itemkey
                             );
    -- 
    -- 承認権限チェックが正常終了の場合
    IF (lv_doc_mgr_return_val = cv_VerifyAuthority_y ) THEN
      lv_proc_kbn_req_aprv := cv_proc_kbn_req_aprv;
    -- 承認権限チェックが異常終了の場合
    ELSE
      lv_proc_kbn_req_aprv := cv_proc_kbn_req_dngtn;
    END IF;
/* 20090515_abe_ST669 END*/
    /* 20090410_abe_T1_0108 END*/
      -- ===============================================
      -- submainの呼び出し（実際の処理はsubmainで行う）
      -- ===============================================
      submain(
          iv_itemtype    => itemtype
        , iv_itemkey     => itemkey
/* 20090515_abe_ST669 START*/
        , iv_process_kbn => lv_proc_kbn_req_aprv  -- 処理区分（発注依頼承認・否認）
--        , iv_process_kbn => cv_proc_kbn_req_aprv  -- 処理区分（発注依頼承認）
/* 20090515_abe_ST669 END*/
        , ov_errbuf      => lv_errbuf             -- エラー・メッセージ  --# 固定 #
        , ov_retcode     => lv_retcode            -- リターン・コード    --# 固定 #
      );
      --
      -- submainが正常終了の場合
      IF lv_retcode = cv_status_normal THEN
        resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_yes;
        --
      -- submainが異常終了の場合
      ELSIF lv_retcode = cv_status_error THEN
        resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
        --
        wf_engine.setitemattrtext(
            itemtype => itemtype
          , itemkey  => itemkey
          , aname    => cv_ib_chk_errmsg
          , avalue   => lv_errbuf
        );
        /* 20090410_abe_T1_0108 START*/
        --
        lv_errbuf_wf := lv_errbuf;
        -- ========================================
        -- A-21. 承認ワークフロー起動(エラー通知)
        -- ========================================
        start_approval_wf_proc(
          iv_itemtype    => itemtype
        , iv_itemkey     => itemkey
        , iv_errmsg      => lv_errbuf_wf          -- エラーメッセージ
        , ov_errbuf      => lv_errbuf             -- エラー・メッセージ  --# 固定 #
        , ov_retcode     => lv_retcode            -- リターン・コード    --# 固定 #
        );
        /* 20090410_abe_T1_0108 END*/
        --
      END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
  END main_for_approval;
  --
/*20090416_yabuki_ST398 START*/
  /**********************************************************************************
   * Procedure Name   : main_for_denegation
   * Description      : メイン処理（発注依頼否認用）
   **********************************************************************************/
  --
  PROCEDURE main_for_denegation(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  )
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'main_for_denegation';  -- プログラム名
    cv_ib_chk_errmsg  CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_ERRMSG';
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);     -- リターン・コード
    lv_errbuf_wf        VARCHAR2(5000);  -- エラー・メッセージ
    ln_notification_id  NUMBER;
    --
  BEGIN
    --
    -- 複数回起動されるため、通知IDが取得できない場合は終了する。
    BEGIN
      SELECT wias.notification_id
      INTO   ln_notification_id
      FROM   wf_item_activity_statuses wias
      WHERE  wias.item_type = itemtype
      AND    wias.item_key  = itemkey
      AND    wias.notification_id IS NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        iv_itemtype    => itemtype
      , iv_itemkey     => itemkey
      , iv_process_kbn => cv_proc_kbn_req_dngtn  -- 処理区分（発注依頼否認）
      , ov_errbuf      => lv_errbuf              -- エラー・メッセージ  --# 固定 #
      , ov_retcode     => lv_retcode             -- リターン・コード    --# 固定 #
    );
    --
    -- submainが正常終了の場合
    IF lv_retcode = cv_status_normal THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_yes;
      --
    -- submainが異常終了の場合
    ELSIF lv_retcode = cv_status_error THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
      lv_errbuf_wf := lv_errbuf;
      -- ========================================
      -- A-21. 承認ワークフロー起動(エラー通知)
      -- ========================================
      start_approval_wf_proc(
        iv_itemtype => itemtype
      , iv_itemkey  => itemkey
      , iv_errmsg   => lv_errbuf_wf    -- エラーメッセージ
      , ov_errbuf   => lv_errbuf       -- エラー・メッセージ  --# 固定 #
      , ov_retcode  => lv_retcode      -- リターン・コード    --# 固定 #
      );
      --
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
  END main_for_denegation;
/*20090416_yabuki_ST398 END*/
--
END XXCSO011A01C;
/
