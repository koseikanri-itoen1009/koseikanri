CREATE OR REPLACE PACKAGE BODY XXCMM003A29C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A29C(body)
 * Description      : 顧客一括更新
 * MD.050           : MD050_CMM_003_A29_顧客一括更新
 * Version          : 1.28
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cust_data_make_wk      ファイルアップロードI/Fテーブル取得処理(A-1)・顧客一括更新用ワークテーブル登録処理(A-2)
 *  rock_and_update_cust   テーブルロック処理(A-3)・顧客一括更新処理(A-4)
 *  close_process          終了処理(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   中村 祐基        新規作成
 *  2009/03/24    1.1   Yutaka.Kuboshima 全角半角チェック処理を追加
 *  2009/10/23    1.2   Yutaka.Kuboshima 障害0001350の対応
 *  2010/01/04    1.3   Yutaka.Kuboshima 障害E_本稼動_00778の対応
 *  2010/01/27    1.4   Yutaka.Kuboshima 障害E_本稼動_01279,E_本稼動_01280の対応
 *  2010/02/15    1.5   Yutaka.Kuboshima 障害E_本稼動_01582 顧客ステータス変更チェックの引数修正
 *                                                          (lv_customer_status -> lv_business_low_type_now)
 *  2010/04/23    1.6   Yutaka.Kuboshima 障害E_本稼動_02295 出荷元保管場所の項目追加
 *                                                          CSV項目数のチェックを追加
 *                                                          実行した職責によるセキュリティを追加
 *  2011/11/28    1.7   窪 和重          障害E_本稼動_07553対応 EDI関連の項目追加
 *  2012/04/19    1.8   仁木 重人        障害E_本稼動_09272対応 訪問対象区分の項目追加
 *                                                               情報欄を最終項目に修正
 *  2013/04/17    1.9   中野 徹也        障害E_本稼動_09963追加対応 項目追加および使用制限変更
 *  2014/04/25    1.10  仁木 重人        障害E_本稼動_11616対応 項目追加
 *  2014/06/19    1.11  仁木 重人        障害E_本稼動_12020対応 保管場所チェック不具合修正
 *                                                              業態小分類チェック修正
 *  2015/03/18    1.12  仁木 重人        障害E_本稼動_12955対応 請求書発行サイクルのチェック追加
 *  2015/04/20    1.13  小路 恭弘        障害E_本稼動_12955対応 業態小分類チェック不具合修正
 *  2017/04/05    1.14  仁木 重人        障害E_本稼動_13976対応 顧客追加情報のeSM関連項目追加
 *  2017/05/18    1.15  仁木 重人        障害E_本稼動_14246対応 請求書印刷単位のチェック追加
 *  2017/06/14    1.16  仁木 重人        障害E_本稼動_14271対応 自販機フォロー委託２次開発
 *  2017/10/18    1.17  大室 慶治        障害E_本稼動_14667対応 MC顧客の中止
 *  2018/07/19    1.18  桐生 和幸        障害E_本稼動_15194対応 通過在庫型区分のチェック追加
 *  2019/01/31    1.19  阿部 直樹        障害E_本稼動_15490対応 顧客追加情報項目変更
 *  2019/02/18    1.20  奈良 和宏        障害E_本稼動_15490対応 顧客追加情報項目変更の不具合対応
 *  2019/04/09    1.21  小山 伸男        障害E_本稼動_15661対応 顧客追加情報項目変更の不具合対応２(法人顧客)
 *  2019/07/26    1.22  阿部 直樹        障害E_本稼動_15748対応 エラーデータスキップ対応→対応不要
 *  2021/05/21    1.23  二村 悠香        障害E_本稼動_16026対応 収益認識 控除用チェーンコード対応
 *  2021/07/21    1.24  二村 悠香        障害E_本稼動_16026再対応 収益認識 控除用チェーンコード対応
 *  2021/10/14    1.25  冨江 広大        障害E_本稼動_17545対応 収益認識 顧客マスタの控除用チェーン変更チェック対応
 *  2022/08/24    1.26  赤地 学          障害E_本稼動_18569対応 事務センター所属チェック（価格表指定）
 *  2024/07/23    1.27  奥山 徹          障害E_本稼動_19877対応 インボイス対応（請求書消費税積上げ計算方式）項目追加
 *  2024/08/06    1.28  奥山 徹          障害E_本稼動_20030対応 顧客マスタ項目追加対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --メッセージ区分
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --メッセージ区分
-- Ver1.26 add start
  gv_xxcok_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCOK'; --メッセージ区分
-- Ver1.26 add end
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_org_id        NUMBER(15)  :=  fnd_global.org_id; --org_id
-- Ver1.26 add start
  gn_user_id        NUMBER          DEFAULT NULL;     --ユーザーID
  gv_user_base_code VARCHAR2(150)   DEFAULT NULL;     --所属拠点コード
-- Ver1.26 add end
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
  get_csv_err_expt          EXCEPTION; --顧客一括更新用CSV取得エラー
  invalid_data_expt         EXCEPTION; --顧客一括更新情報不正例外
--
  update_cust_err_expt      EXCEPTION; --顧客マスタ更新エラー
  update_party_err_expt     EXCEPTION; --パーティマスタ更新エラー
  update_csu_err_expt       EXCEPTION; --顧客使用目的マスタ更新エラー
  update_location_err_expt  EXCEPTION; --顧客事業所マスタ更新エラー
--
  cust_rock_err_expt        EXCEPTION; --ロックエラー
--
  PRAGMA EXCEPTION_INIT(cust_rock_err_expt,-54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(12)  := 'XXCMM003A29C';                    --パッケージ名
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                               --カンマ
  --
  cv_header_str_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00332';                --CSVファイルヘッダ文字列
  cv_no_csv_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00312';                --顧客一括更新用CSV取得失敗メッセージ
  cv_parameter_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';                --入力パラメータノート
  cv_file_name_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';                --ファイル名ノート
  --エラーメッセージ
  cv_required_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00342';                --必須項目エラー
  cv_val_form_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00322';                --型・桁数エラーメッセージ
  cv_lookup_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00314';                --参照表存在チェックエラーメッセージ
  cv_mst_err_msg              CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00316';                --マスタ存在チェックエラーメッセージ
  cv_double_byte_kana_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00317';                --全角カタカナチェックエラーメッセージ
  cv_status_func_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00336';                --顧客ステータス変更エラー（遷移不可）
  cv_status_modify_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00319';                --顧客ステータス変更チェックエラーメッセージ
  cv_trust_val_invalid        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00315';                --値エラー
  cv_cust_addon_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00320';                --顧客追加情報マスタ存在チェックエラー
  cv_corp_err_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00321';                --顧客法人情報マスタ存在チェックエラー
  cv_invalid_data_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00337';                --データエラー時出力メッセージ
  cv_invalid_header_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00338';                --ヘッダエラー時メッセージ
  cv_rock_err_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00313';                --ロックエラー時メッセージ
  cv_update_cust_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00323';                --顧客マスタ更新エラー時メッセージ
  cv_update_party_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00324';                --パーティマスタ更新エラー時メッセージ
  cv_update_csu_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00325';                --顧客使用目的エラー時メッセージ
  cv_update_location_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00326';                --顧客事業所エラー時メッセージ
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
  cv_double_byte_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00344';                --全角文字チェックエラー時メッセージ
  cv_single_byte_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00345';                --半角文字チェックエラー時メッセージ
  cv_postal_code_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00346';                --郵便番号チェックエラー時メッセージ
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
  cv_correlation_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00351';                --相関チェックエラー時メッセージ
  cv_flex_value_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00352';                --値セット存在チェックエラー時メッセージ
  cv_set_item_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00353';                --項目設定チェックエラー時メッセージ
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- Ver1.18 add start
  cv_chain_tsukazaiko_err_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00400';                --チェーン店コード、通過在庫型区分相関エラー時メッセージ
-- Ver1.18 add end
--
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
  cv_profile_err_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';                --プロファイル取得エラー
  cv_stop_date_val_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00354';                --中止決裁日妥当性チェックエラー
  cv_stop_date_future_err_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00355';                --中止決裁日未来日チェックエラー
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
  cv_item_num_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00028';                --データ項目数エラー
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
  cv_cust_class_kbn_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00357';                --顧客区分ステータスチェックエラー
  cv_code_person_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00358';                --獲得拠点営業員相関チェックエラー
  cv_code_relation_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00359';                --獲得拠点従業員紐付きチェックエラー
  cv_person_relation_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00360';                --獲得従業員拠点紐付きチェックエラー
  cv_new_point_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00361';                --新規ポイント範囲チェックエラー
  cv_intro_err_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00362';                --未登録チェックエラー
  cv_intro_person_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00363';                --獲得営業員紹介者チェックエラー
  cv_mst_intro_per_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00364';                --紹介者マスタチェックエラー
  cv_base_code_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00365';                --本部担当拠点必須エラー
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
  cv_tel_form_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00373';                --電話番号チェックエラー
  cv_range_err_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00374';                --範囲チェックエラー
  cv_conc_day_rel_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00375';                --消化計算締め日相関チェックエラー
  cv_conc_day_val_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00376';                --消化計算締め日妥当性チェックエラー
  cv_conc_day_lastday_err_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00377';                --消化計算締め日月末日付チェックエラー
  cv_now_update_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00378';                --現在値更新可否チェックエラー
  cv_deliv_rel_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00379';                --納品拠点相関チェックエラー
  cv_ss_code_rel_err1_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00381';                --出荷元保管場所相関チェック１エラー
  cv_ss_code_rel_err2_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00382';                --出荷元保管場所相関チェック２エラー
-- Ver1.11 del start
--  cv_bz_low_type_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00383';                --業態(小分類)妥当性チェックエラー
-- Ver1.11 del end
-- Ver1.10 add end
-- Ver1.12 add start
  cv_invoice_cycle_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00384';                --請求書発行サイクルチェックエラー
-- Ver1.12 add end
-- Ver1.15 add start
  cv_inv_prt_unit_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10358';                --請求書印刷単位チェックエラー
-- Ver1.15 add end
-- Ver1.16 add start
  cv_offset_cust_div_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10362';                --相殺用顧客コード存在チェックエラー
  cv_offset_cust_rel_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10363';                --相殺用顧客コード関連チェックエラー
  cv_bp_cust_exists_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10364';                --取引先顧客コード重複チェックエラー
-- Ver1.16 add end
-- Ver1.19 add start
  cv_latitude_exists_err_mst  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10490';                --カテゴリー商品計上区分必須チェックエラー
-- Ver1.19 add end
-- Ver1.20 add start
  cv_latitude_not_null_err    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10492';                --カテゴリー商品計上区分指定エラー
-- Ver1.20 add end
-- Ver1.25 add start
  cv_dedu_chain_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10503';                --控除消込ヘッダー情報の消込ステータスチェックエラー
-- Ver1.25 add end
-- Ver1.26 add start
  cv_msg_user_id_err          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10594';                -- ユーザーID取得エラーメッセージ
  cv_msg_user_base_code_err   CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00012';                -- 所属拠点コード取得エラーメッセージ
  cv_msg_base_business_err    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10505';                -- 事務センター所属チェックエラーメッセージ
  cv_base_code_business       CONSTANT VARCHAR2(25)  := 'XXCMM_BASE_CODE_BUSINESS';        -- 参照タイプ・拠点コード（事務センター）
-- Ver1.26 add end
-- Ver1.27 add start
  cv_msg_invoice_tax_div_err  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10507';                -- 請求書消費税積上げ計算方式チェックエラーメッセージ
-- Ver1.27 add end
-- Ver1.28 add start
  cv_an_attr_msg              CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10370';                -- 英数字型チェックエラーメッセージ
-- Ver1.28 add end
--
  cv_param                    CONSTANT VARCHAR2(5)   := 'PARAM';                           --パラメータトークン
  cv_value                    CONSTANT VARCHAR2(5)   := 'VALUE';                           --パラメータ値トークン
  cv_item                     CONSTANT VARCHAR2(4)   := 'ITEM';                            --ITEMトークン
  cv_file_id                  CONSTANT VARCHAR2(7)   := 'FILE_ID';                         --パラメータ・ファイルID
  cv_file_content_type        CONSTANT VARCHAR2(17)  := 'FILE_CONTENT_TYPE';               --パラメータ・ファイルタイプ
  cv_file_name                CONSTANT VARCHAR2(9)   := 'FILE_NAME';                       --ファイル名トークン
  cv_element_vc2              CONSTANT VARCHAR2(1)   := '0';                               --項目属性・検証なし
  cv_element_num              CONSTANT VARCHAR2(1)   := '1';                               --項目属性・数値
  cv_element_dat              CONSTANT VARCHAR2(1)   := '2';                               --項目属性・日付
  cv_null_bar                 CONSTANT VARCHAR2(1)   := '-';                               --NULL更新文字
  cv_null_ng                  CONSTANT VARCHAR2(7)   := 'NULL_NG';                         --必須フラグ・必須
  cv_null_ok                  CONSTANT VARCHAR2(7)   := 'NULL_OK';                         --必須フラグ・任意
  cv_customer_class           CONSTANT VARCHAR2(14)  := 'CUSTOMER CLASS';                  --参照タイプ・顧客区分
  cv_cust_code                CONSTANT VARCHAR2(9)   := 'CUST_CODE';                       --顧客コードトークン
  cv_cust                     CONSTANT VARCHAR2(10)  := '顧客コード';                      --顧客コード
  cv_business_low_type        CONSTANT VARCHAR2(21)  := 'XXCMM_CUST_GYOTAI_SHO';           --参照タイプ・業態（小分類）
  cv_bus_low_type             CONSTANT VARCHAR2(14)  := '業態（小分類）';                  --業態（小分類）
  cv_customer_status          CONSTANT VARCHAR2(25)  := 'XXCMM_CUST_KOKYAKU_STATUS';       --参照タイプ・顧客ステータス
  cv_cust_status              CONSTANT VARCHAR2(14)  := '顧客ステータス';                  --顧客ステータス
  cv_pre_status               CONSTANT VARCHAR2(10)  := 'PRE_STATUS';                      --顧客ステータス変更前トークン
  cv_will_status              CONSTANT VARCHAR2(11)  := 'WILL_STATUS';                     --顧客ステータス変更後トークン
  cv_modify_err               CONSTANT VARCHAR2(1)   := '0';                               --ステータス変更チェック・ステータスエラー
  cv_ret_code                 CONSTANT VARCHAR2(8)   := 'RET_CODE';                        --ステータス変更チェック・ステータストークン
  cv_ret_msg                  CONSTANT VARCHAR2(7)   := 'RET_MSG';                         --ステータス変更チェック・メッセージトークン
  cv_stop_approved            CONSTANT VARCHAR2(2)   := '90';                              --顧客ステータス・中止決済済
  cv_approval_reason          CONSTANT VARCHAR2(22)  := 'XXCMM_CUST_CHUSHI_RIYU';          --参照タイプ・中止理由
  cv_appr_reason              CONSTANT VARCHAR2(8)   := '中止理由';                        --中止理由
  cv_appr_date                CONSTANT VARCHAR2(10)  := '中止決済日';                      --中止決済日
  cv_ar_invoice_code          CONSTANT VARCHAR2(22)  := 'XXCMM_INVOICE_GRP_CODE';          --参照コード・売掛コード１（請求書）
  cv_ar_invoice               CONSTANT VARCHAR2(22)  := '売掛コード１（請求書）';          --売掛コード１（請求書）
  cv_ar_location_code         CONSTANT VARCHAR2(22)  := '売掛コード２（事業所）';          --売掛コード２（事業所）
  cv_ar_others_code           CONSTANT VARCHAR2(22)  := '売掛コード３（その他）';          --売掛コード３（その他）
  cv_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                           --テーブルトークン
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--  cv_invoice_class            CONSTANT VARCHAR2(29)  := 'XXCMM_CUST_SEKYUSYO_HAKKO_KBN';   --参照コード・請求書発行区分
--  cv_invoice_kbn              CONSTANT VARCHAR2(14)  := '請求書発行区分';                  --請求書発行区分
  cv_invoice_class            CONSTANT VARCHAR2(30)  := 'XXCMM_INVOICE_PRINTING_UNIT';     --参照コード・請求書印刷単位
  cv_invoice_kbn              CONSTANT VARCHAR2(14)  := '請求書印刷単位';                  --請求書印刷単位
  cv_industry_div             CONSTANT VARCHAR2(4)   := '業種';                            --業種
  cv_bill_base_code           CONSTANT VARCHAR2(8)   := '請求拠点';                        --請求拠点
  cv_receiv_base_code         CONSTANT VARCHAR2(8)   := '入金拠点';                        --入金拠点
  cv_delivery_base_code       CONSTANT VARCHAR2(8)   := '納品拠点';                        --納品拠点
  cv_selling_transfer_div     CONSTANT VARCHAR2(12)  := '売上実績振替';                    --売上実績振替
  cv_card_company             CONSTANT VARCHAR2(16)  := 'カード会社コード';                --カード会社コード
  cv_wholesale_ctrl_code      CONSTANT VARCHAR2(14)  := '問屋管理コード';                  --問屋管理コード
  cv_price_list               CONSTANT VARCHAR2(6)   := '価格表';                          --価格表
-- 2009/10/23 Ver1.2 modify end by Yutaka.Kuboshima
  cv_invoice_issue_cycle      CONSTANT VARCHAR2(25)  := 'XXCMM_INVOICE_ISSUE_CYCLE';       --参照コード・請求書発行サイクル
  cv_invoice_cycle            CONSTANT VARCHAR2(18)  := '請求書発行サイクル';              --請求書発行サイクル
  cv_invoice_form             CONSTANT VARCHAR2(28)  := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';    --参照コード・請求書出力形式
  cv_invoice_ksk              CONSTANT VARCHAR2(14)  := '請求書出力形式';                  --請求書出力形式
  cv_payment_term_id          CONSTANT VARCHAR2(8)   := '支払条件';                        --支払条件
  cv_payment_term_second      CONSTANT VARCHAR2(11)  := '第2支払条件';                     --第2支払条件
  cv_payment_term_third       CONSTANT VARCHAR2(11)  := '第3支払条件';                     --第3支払条件
  cv_payment_term             CONSTANT VARCHAR2(14)  := '支払条件マスタ';                  --支払条件
  cv_xxcmm_chain_code         CONSTANT VARCHAR2(16)  := 'XXCMM_CHAIN_CODE';                --参照コード・チェーン店
  cv_sales_chain_code         CONSTANT VARCHAR2(26)  := 'チェーン店コード（販売先）';      --チェーン店コード（販売先）
  cv_delivery_chain_code      CONSTANT VARCHAR2(26)  := 'チェーン店コード（納品先）';      --チェーン店コード（納品先）
  cv_policy_chain_code        CONSTANT VARCHAR2(26)  := 'チェーン店コード（政策用）';      --チェーン店コード（政策用）
  cv_edi_chain                CONSTANT VARCHAR2(26)  := 'チェーン店コード（ＥＤＩ）';      --チェーン店コード（ＥＤＩ）
  cv_addon_cust_mst           CONSTANT VARCHAR2(18)  := '顧客追加情報マスタ';              --顧客追加情報マスタ（文字列）
  cv_edi_class                CONSTANT VARCHAR2(2)   := '18';                              --顧客区分・チェーン店
  cv_trust_corp               CONSTANT VARCHAR2(2)   := '13';                              --顧客区分・法人顧客（与信管理先）
  cv_store_code               CONSTANT VARCHAR2(10)  := '店舗コード';                      --店舗コード
  cv_postal_code              CONSTANT VARCHAR2(8)   := '郵便番号';                        --郵便番号
  cv_state                    CONSTANT VARCHAR2(8)   := '都道府県';                        --都道府県
  cv_city                     CONSTANT VARCHAR2(6)   := '市・区';                          --市・区
  cv_address1                 CONSTANT VARCHAR2(5)   := '住所1';                           --住所1
  cv_address2                 CONSTANT VARCHAR2(5)   := '住所2';                           --住所2
  cv_address3                 CONSTANT VARCHAR2(10)  := '地区コード';                      --地区コード
  cv_cust_chiku_code          CONSTANT VARCHAR2(21)  := 'XXCMM_CUST_CHIKU_CODE';           --参照コード・地区コード
  cv_credit_limit             CONSTANT VARCHAR2(21)  := '与信限度額';                      --与信限度額
  cv_decide_div               CONSTANT VARCHAR2(20)  := 'XXCMM_CUST_SOHYO_KBN';            --参照コード・判定区分
  cv_decide                   CONSTANT VARCHAR2(8)   := '判定区分';                        --判定区分
--
  cv_cust_acct_table          CONSTANT VARCHAR2(16)  := 'HZ_CUST_ACCOUNTS';                --顧客マスタ
  cv_lookup_values            CONSTANT VARCHAR2(20)  := 'FND_LOOKUP_VALUES_VL';            --参照表トークン
  cv_col_name                 CONSTANT VARCHAR2(14)  := 'INPUT_COL_NAME';                  --列名トークン
  cv_input_val                CONSTANT VARCHAR2(15)  := 'INPUT_COL_VALUE';                 --値トークン
  cv_cust_class               CONSTANT VARCHAR2(8)   := '顧客区分';                        --顧客区分（列名）
  cv_cust_class_us            CONSTANT VARCHAR2(10)  := 'CUST_CLASS';                      --顧客区分トークン
  cv_cust_name                CONSTANT VARCHAR2(8)   := '顧客名称';                        --顧客名称（列名）
  cv_cust_name_kana           CONSTANT VARCHAR2(12)  := '顧客名称カナ';                    --顧客名称カナ（列名）
  cv_ryaku                    CONSTANT VARCHAR2(4)   := '略称';                            --略称
  cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY-MM-DD';                      --日付書式
--
  cv_conc_request_id          CONSTANT VARCHAR2(15)  := 'CONC_REQUEST_ID';                 --要求ID取得用文字列
  cv_prog_appl_id             CONSTANT VARCHAR2(12)  := 'PROG_APPL_ID';                    --コンカレント・プログラム･アプリケーションID取得用文字列
  cv_conc_program_id          CONSTANT VARCHAR2(15)  := 'CONC_PROGRAM_ID';                 --コンカレント・プログラムID取得用文字列
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
  cv_invoice_code             CONSTANT VARCHAR2(14)  := '請求書用コード';                  --請求書用コード
-- Ver1.27 add start
  cv_invoice_tax_div          CONSTANT VARCHAR2(30)  := '請求書消費税積上げ計算方式';      --請求書消費税積上げ計算方式
  cv_invoice_tax_div_tk       CONSTANT VARCHAR2(15)  := 'INVOICE_TAX_DIV';                 --請求書消費税積上げ計算方式トークン
-- Ver1.27 add end
-- Ver1.28 add start
  cv_pos_enterprise_code      CONSTANT VARCHAR2(30)  := 'POS企業コード';                   --POS企業コード
  cv_pos_store_code           CONSTANT VARCHAR2(30)  := 'POS店舗コード';                   --POS店舗コード
  gv_cnst_err_msg_space12     CONSTANT VARCHAR2(12)  := '            ';                    -- スペース
-- Ver1.28 add end
  cv_cond_col_name            CONSTANT VARCHAR2(15)  := 'COND_COL_NAME';                   --相関列名トークン
  cv_cond_col_val             CONSTANT VARCHAR2(15)  := 'COND_COL_VALUE';                  --相関値トークン
  cv_kokyaku_kbn              CONSTANT VARCHAR2(2)   := '10';                              --顧客区分(顧客)
  cv_uesama_kbn               CONSTANT VARCHAR2(2)   := '12';                              --顧客区分(上様顧客)
  cv_urikake_kbn              CONSTANT VARCHAR2(2)   := '14';                              --顧客区分(売掛管理先)
  cv_tenpo_kbn                CONSTANT VARCHAR2(2)   := '15';                              --顧客区分(店舗営業)
  cv_tonya_kbn                CONSTANT VARCHAR2(2)   := '16';                              --顧客区分(問屋帳合先)
  cv_keikaku_kbn              CONSTANT VARCHAR2(2)   := '17';                              --顧客区分(計画立案用)
  cv_hyakkaten_kbn            CONSTANT VARCHAR2(2)   := '19';                              --顧客区分(百貨店伝区)
  cv_seikyusho_kbn            CONSTANT VARCHAR2(2)   := '20';                              --顧客区分(請求書用)
  cv_toukatu_kbn              CONSTANT VARCHAR2(2)   := '21';                              --顧客区分(統括請求書用)
  cv_yes                      CONSTANT VARCHAR2(1)   := 'Y';                               --Yフラグ
  cv_no                       CONSTANT VARCHAR2(1)   := 'N';                               --Nフラグ
  cv_language_ja              CONSTANT VARCHAR2(2)   := 'JA';                              --言語・日本語
  cv_list_type_prl            CONSTANT VARCHAR2(3)   := 'PRL';                             --リストタイプ・PRL
  cv_card_company_div         CONSTANT VARCHAR2(1)   := '1';                               --カード会社区分
  cv_gyotai_full_syoka_vd     CONSTANT VARCHAR2(2)   := '24';                              --業態（小分類）：フルサービス(消化)VD
  cv_gyotai_full_vd           CONSTANT VARCHAR2(2)   := '25';                              --業態（小分類）：フルサービスVD
  cv_aff_dept                 CONSTANT VARCHAR2(15)  := 'XX03_DEPARTMENT';                 --AFF部門マスタ参照タイプ
  cv_gyotai_kbn               CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_KBN';           --参照コード・業種
  cv_uriage_jisseki_furi      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_URIAGE_JISSEKI_FURI';  --参照コード・売上実績振替
  cv_tonya_code               CONSTANT VARCHAR2(30)  := 'XXCMM_TONYA_CODE';                --参照コード・問屋管理コード
  cv_qp_list_headers_table    CONSTANT VARCHAR2(30)  := 'QP_LIST_HEADERS_B';               --価格表マスタ
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04v Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
  cv_profile_gl_cal           CONSTANT VARCHAR2(30)  := 'XXCMM1_003A00_GL_PERIOD_MN';      --会計カレンダ名定義ﾌﾟﾛﾌｧｲﾙ
  cv_profile_ar_bks           CONSTANT VARCHAR2(30)  := 'XXCMM1_003A15_AR_BOOKS_NM';       --営業帳簿定義名ﾌﾟﾛﾌｧｲﾙ
  cv_tkn_ng_profile           CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                      --プロファイル名トークン
  cv_gl_cal_name              CONSTANT VARCHAR2(30)  := '会計カレンダ名';                  --会計カレンダ名
  cv_set_of_books_name        CONSTANT VARCHAR2(30)  := '営業帳簿定義名';                  --営業帳簿定義名
  cv_close_status             CONSTANT VARCHAR2(1)   := 'C';                               --会計期間：クローズ
  cv_apl_short_nm_ar          CONSTANT VARCHAR2(2)   := 'AR';                              --アプリケーション：AR
-- 2010/01/04v Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
  cv_organization_code        CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';        --在庫組織コードプロファイル
  cv_profile_org_code         CONSTANT VARCHAR2(30)  := '在庫組織コード';                  --在庫組織コードプロファイル名
  cv_ship_storage_code        CONSTANT VARCHAR2(14)  := '出荷元保管場所';                  --出荷元保管場所
  cv_second_inv_mst           CONSTANT VARCHAR2(14)  := '保管場所マスタ';                  --保管場所マスタ
  cv_csv_item_num             CONSTANT VARCHAR2(30)  := 'XXCMM1_003A29_ITEM_NUM';          --顧客一括更新データ項目数
  cv_csv_item_num_name        CONSTANT VARCHAR2(30)  := '顧客一括更新データ項目数';        --顧客一括更新データ項目数名
  cv_management_resp          CONSTANT VARCHAR2(30)  := 'XXCMM1_MANAGEMENT_RESP';          --職責管理プロファイル
  cv_management_resp_name     CONSTANT VARCHAR2(30)  := '職責管理プロファイル';            --職責管理プロファイル名
  cv_joho_kanri_resp          CONSTANT VARCHAR2(30)  := 'XXCMM_RESP_011';                  --職責管理プロファイル値(情報管理_担当者)
  cv_count_token              CONSTANT VARCHAR2(30)  := 'COUNT';                           --件数トークン
  cv_xxcmm_003_a29c_name      CONSTANT VARCHAR2(30)  := '顧客一括更新';                    --顧客一括更新名
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
  cv_delivery_order           CONSTANT VARCHAR2(13)  := '配送順（EDI）';                   --配送順（EDI）
  cv_edi_district_code        CONSTANT VARCHAR2(20)  := 'EDI地区コード（EDI）';            --EDI地区コード（EDI）
  cv_edi_district_name        CONSTANT VARCHAR2(16)  := 'EDI地区名（EDI）';                --EDI地区名（EDI）
  cv_edi_district_kana        CONSTANT VARCHAR2(20)  := 'EDI地区名カナ（EDI）';            --EDI地区名カナ（EDI）
  cv_tsukagatazaiko_div       CONSTANT VARCHAR2(21)  := '通過在庫型区分（EDI）';           --通過在庫型区分（EDI）
  cv_deli_center_code         CONSTANT VARCHAR2(21)  := 'EDI納品センターコード';           --EDI納品センターコード
  cv_deli_center_name         CONSTANT VARCHAR2(17)  := 'EDI納品センター名';               --EDI納品センター名
  cv_edi_forward_number       CONSTANT VARCHAR2(11)  := 'EDI伝送追番';                     --EDI伝送追番
  cv_cust_store_name          CONSTANT VARCHAR2(12)  := '顧客店舗名称';                    --顧客店舗名称
  cv_torihikisaki_code        CONSTANT VARCHAR2(12)  := '取引先コード';                    --取引先コード
  cv_tsukagatazaiko_kbn       CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_TSUKAGATAZAIKO_KBN';   --参照コード・通過在庫型区分
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
  cv_vist_target_div          CONSTANT VARCHAR2(30)  := '訪問対象区分';                    --訪問対象区分
  cv_homon_taisyo_kbn         CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_HOMON_TAISYO_KBN';     --参照コード・訪問対象区分
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
  cv_approved_status          CONSTANT VARCHAR2(2)   := '30';                              --顧客ステータス・承認済
  cv_cnvs_base_code           CONSTANT VARCHAR2(30)  := '獲得拠点コード';                  --獲得拠点コード
  cv_cnvs_business_person     CONSTANT VARCHAR2(30)  := '獲得営業員';                      --獲得営業員
  cv_new_point_div            CONSTANT VARCHAR2(30)  := '新規ポイント区分';                --新規ポイント区分
  cv_new_point_div_type       CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_SHINKI_POINT_KBN';     --参照タイプ・新規ポイント区分
  cv_new_point                CONSTANT VARCHAR2(30)  := '新規ポイント';                    --新規ポイント
  cv_intro_base_code          CONSTANT VARCHAR2(30)  := '紹介拠点コード';                  --紹介拠点コード
  cv_intro_base_code_val      CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';                 --値セット・紹介拠点コード
  cv_intro_business_person    CONSTANT VARCHAR2(30)  := '紹介営業員';                      --紹介営業員
  cv_base_code                CONSTANT VARCHAR2(30)  := '本部担当拠点';                    --本部担当拠点
  cv_tdb_code                 CONSTANT VARCHAR2(30)  := 'TDBコード';                       --TDBコード
  cv_approval_date            CONSTANT VARCHAR2(30)  := '決裁日付';                        --決裁日付
  cv_intro_chain_code1        CONSTANT VARCHAR2(30)  := '紹介者チェーンコード１';          --紹介者チェーンコード１
-- Ver1.23 mod start
--  cv_intro_chain_code2        CONSTANT VARCHAR2(30)  := '紹介者チェーンコード２';          --紹介者チェーンコード２
  cv_intro_chain_code2        CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-30409';                --控除用チェーンコード
-- Ver1.23 mod end
  cv_sales_head_base_code     CONSTANT VARCHAR2(30)  := '販売先本部担当拠点';              --販売先本部担当拠点
  cn_point_min                CONSTANT NUMBER        := 0;                                 --新規ポイント最小値
  cn_point_max                CONSTANT NUMBER        := 999;                               --新規ポイント最大値
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
  --参照タイプ
  cv_syohizei_kbn             CONSTANT VARCHAR2(30)  := 'XXCMM_CSUT_SYOHIZEI_KBN';         --参照タイプ・消費税区分
  cv_peekcut_start_time       CONSTANT VARCHAR2(30)  := 'XXCMM_PEEKCUT_START_TIME';        --参照タイプ・ピークカット開始時刻
  --メッセージトークン
  cv_token_min_value          CONSTANT VARCHAR2(30)  := 'MIN_VALUE';                       --最小値
  cv_token_max_value          CONSTANT VARCHAR2(30)  := 'MAX_VALUE';                       --最大値
  cv_token_interval           CONSTANT VARCHAR2(30)  := 'INTERVAL';                        --日付間隔
  cv_token_conc_day1          CONSTANT VARCHAR2(30)  := 'CONC_DAY1';                       --消化計算締め日の項目名1
  cv_token_conc_day2          CONSTANT VARCHAR2(30)  := 'CONC_DAY2';                       --消化計算締め日の項目名2
-- Ver1.26 add start
  cv_token_user_id            CONSTANT  VARCHAR2(30) := 'USER_ID';                         -- ユーザーID
-- Ver1.26 add end
  --項目名
  cv_address_lines_phonetic   CONSTANT VARCHAR2(10)  := '電話番号';                        --電話番号
  cv_address4                 CONSTANT VARCHAR2(10)  := 'FAX';                             --FAX
  cv_sale_base_code           CONSTANT VARCHAR2(30)  := '売上拠点';                        --売上拠点
  cv_tax_div                  CONSTANT VARCHAR2(30)  := '消費税区分';                      --消費税区分
  cv_longitude                CONSTANT VARCHAR2(30)  := 'ピークカット開始時刻';            --ピークカット開始時刻
  cv_bom_calendars            CONSTANT VARCHAR2(30)  := '稼働日カレンダ';                  --稼働日カレンダ
  cv_bom_calendars_table      CONSTANT VARCHAR2(30)  := 'BOM_CALENDARS';                   --稼働日カレンダ表
  cv_rate                     CONSTANT VARCHAR2(60)  := '消化計算用掛率';                  --消化計算用掛率
  cv_rcv_dsct_rate            CONSTANT VARCHAR2(60)  := '入金値引率';                      --入金値引率
  cv_conclusion_day1          CONSTANT VARCHAR2(60)  := '消化計算締め日1';                 --消化計算締め日1
  cv_conclusion_day2          CONSTANT VARCHAR2(60)  := '消化計算締め日2';                 --消化計算締め日2
  cv_conclusion_day3          CONSTANT VARCHAR2(60)  := '消化計算締め日3';                 --消化計算締め日3
  cv_store_cust_code          CONSTANT VARCHAR2(60)  := '店舗営業用顧客コード';            --店舗営業用顧客コード
  --値(文字)
  cv_in_transfer              CONSTANT VARCHAR2(1)   := '1';                               --振替あり
  cv_gyotai_inshop            CONSTANT VARCHAR2(2)   := '21';                              --業態（小分類）：インショップ
  cv_gyotai_tosya_tyokuei     CONSTANT VARCHAR2(2)   := '22';                              --業態（小分類）：当社直営店
  cv_gyotai_nohin_vd          CONSTANT VARCHAR2(2)   := '26';                              --業態（小分類）：納品VD
  cv_gyotai_syoka_vd          CONSTANT VARCHAR2(2)   := '27';                              --業態（小分類）：消化VD
  cv_center_stock_order       CONSTANT VARCHAR2(2)   := '12';                              --センタ納品・在庫型・受注
  cv_center_stock_delivery    CONSTANT VARCHAR2(2)   := '13';                              --センタ納品・在庫型（納品確定）
  cv_center_no_stock          CONSTANT VARCHAR2(2)   := '24';                              --店舗納品・無し
  cv_hokan_bunrui_3           CONSTANT VARCHAR2(1)   := '3';                               --保管場所分類
  cv_dummy_0                  CONSTANT VARCHAR2(1)   := '0';                               --NULLダミー値(文字)
-- Ver1.12 add start
  cv_invoice_form_4           CONSTANT VARCHAR2(10)  := '4';                               --請求書出力形式：業者委託
  cv_invoice_cycle_1          CONSTANT VARCHAR2(10)  := '1';                               --請求書発行サイクル：第一営業日
  cv_a_flag                   CONSTANT VARCHAR2(1)   := 'A';                               --ステータス(有効)
  cv_bill_to                  CONSTANT VARCHAR2(7)   := 'BILL_TO';                         --使用目的・請求先
  cv_other_to                 CONSTANT VARCHAR2(8)   := 'OTHER_TO';                        --使用目的・その他
-- Ver1.12 add end
  --値(数値)
  cn_rate_min                 CONSTANT NUMBER        := 0;                                 --消化計算用掛率最小値
  cn_rate_max                 CONSTANT NUMBER        := 999;                               --消化計算用掛率最大値
  cn_rcv_dsct_rate_min        CONSTANT NUMBER        := 0;                                 --入金値引率最小値
  cn_rcv_dsct_rate_max        CONSTANT NUMBER        := 99.9;                              --入金値引率最大値
  cn_conc_day_min             CONSTANT NUMBER        := 1;                                 --消化計算日付最小値
  cn_conc_day_max             CONSTANT NUMBER        := 30;                                --消化計算日付最大値
  cn_conclusion_interval      CONSTANT NUMBER        := 5;                                 --消化計算日付間隔
  cn_dummy_0                  CONSTANT NUMBER        := 0;                                 --NULLダミー値(数値)
-- Ver1.10 add end
-- Ver1.14 add start
  --参照タイプ
  cv_lkp_esm_target_div       CONSTANT VARCHAR2(30)  := 'XXCMM_ESM_TARGET_DIV';             --参照タイプ・ストレポ＆商談くん連携対象フラグ
  cv_lkp_esm_cust_class       CONSTANT VARCHAR2(30)  := 'XXCMM_ESM_CUSTOMER_CLASS';         --参照タイプ・eSM対象顧客区分
  --項目名
  cv_esm_target_div           CONSTANT VARCHAR2(36)  := 'ストレポ＆商談くん連携対象フラグ'; --ストレポ＆商談くん連携対象フラグ
-- Ver1.14 add end
-- Ver1.16 add start
  --メッセージトークン
  cv_value2                   CONSTANT VARCHAR2(6)   := 'VALUE2';                           --トークン
  --参照タイプ
  cv_bp_customer_code         CONSTANT VARCHAR2(30)  := '取引先顧客コード';                 --取引先顧客コード
  cv_offset_cust_div_1        CONSTANT VARCHAR2(1)   := '1';                                --相殺用顧客区分：相殺用顧客
-- Ver1.16 add end
-- 2017/10/18 Ver1.17 E_本稼動_14667 add start by Y.Omuro
  cv_mc_candidates            CONSTANT VARCHAR2(2)   := '10';                               --顧客ステータス・MC候補
  cv_mc                       CONSTANT VARCHAR2(2)   := '20';                               --顧客ステータス・MC
-- 2017/10/18 Ver1.17 E_本稼動_14667 add end by Y.Omuro
-- Ver1.19 add start
  --参照タイプ
  cv_lkp_cat_prod_div         CONSTANT VARCHAR2(30)  := 'XXCMM_CATEGORY_PRODUCT_DIV';       --参照タイプ・カテゴリー商品計上区分
  cv_lkp_cat_prod_unn         CONSTANT VARCHAR2(30)  := 'XXCMM_CAT_PROD_DIV_UNNECESSARY';   --参照タイプ・カテゴリー商品計上区分不要業態小分類定義
  --メッセージトークン
  cv_input_data               CONSTANT VARCHAR2(10)  := 'INPUT_DATA';                       --トークン
  --項目名
  cv_latitude_div             CONSTANT VARCHAR2(22)  := 'カテゴリー商品計上区分';           --カテゴリー商品計上区分
  --固定値
  cv_gyomu_kokyaku_resp       CONSTANT VARCHAR2(30)  := 'XXCMM_RESP_006';                   --職責管理プロファイル値(業務管理部(顧客))
-- Ver1.19 add end
-- Ver1.25 add start
  --メッセージトークン
  cv_dedu_chain_code          CONSTANT VARCHAR2(30)  := 'DEDU_CHAIN_CODE';                   --控除用チェーンコード
  cv_token_recon_slip_num     CONSTANT VARCHAR2(30)  := 'RECON_SLIP_NUM';                    --支払伝票番号
  --参照タイプ
  cv_lkp_dedu_data_type       CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- 控除データ種類
-- Ver1.25 add end
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
  gd_process_date             DATE;                                                        --業務日付
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
  gv_gl_cal_code              VARCHAR2(30);                                                --会計カレンダコード値
  gv_ar_set_of_books          VARCHAR2(30);                                                --営業システム会計帳簿定義名
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
  gv_organization_code        VARCHAR2(30);                                                --在庫組織コード
  gn_item_num                 NUMBER;                                                      --顧客一括更新データ項目数
  gv_management_resp          VARCHAR2(30);                                                --職責管理プロファイル
  gv_resp_flag                VARCHAR2(1);                                                 --職責管理フラグ(情報管理部：'Y' その他：'N')
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : cust_data_make_wk
   * Description      : ファイルアップロードI/Fテーブル取得処理(A-1)・顧客一括更新用ワークテーブル登録処理(A-2)
   ***********************************************************************************/
  PROCEDURE cust_data_make_wk(
    in_file_id              IN  NUMBER,       --   ファイルID
    iv_format_pattern       IN  VARCHAR2,     --   ファイルフォーマット
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_data_make_wk'; -- プログラム名
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
    -- 構造体宣言
    lr_cust_data_table       xxccp_common_pkg2.g_file_data_tbl;
--
    lv_item_errbuf           VARCHAR2(5000);  -- エラー・メッセージ
    lv_item_retcode          VARCHAR2(1);     -- リターン・コード
    lv_item_errmsg           VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    --各格納用変数
    lv_upload_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE := NULL;  --ファイルアップロードIFテーブル.ファイル名
--
    lv_temp                  VARCHAR2(32767) := NULL;                     --顧客一括更新ワークテーブル登録用変数
    ln_index                 binary_integer;                              --文字列構造体参照用添字
    ln_first_data            NUMBER(1)       := 1;                        --ヘッダデータ識別子
    lr_cust_wk_table         xxcmm_wk_cust_batch_regist%ROWTYPE;          --ファイルアップロードIFテーブル型レコード変数
--
    ln_cust_id               hz_cust_accounts.cust_account_id%TYPE;       --ローカル変数顧客ID
    ln_party_id              hz_cust_accounts.party_id%TYPE;              --ローカル変数パーティID
    lv_customer_code         VARCHAR2(100)   := NULL;                     --ローカル変数・顧客コード
    lv_cust_code_mst         hz_cust_accounts.account_number%TYPE;        --顧客コード存在確認用変数
    ln_cust_addon_mst        xxcmm_cust_accounts.customer_id%TYPE;        --顧客追加情報存在確認用変数
    ln_cust_corp_mst         xxcmm_mst_corporate.customer_id%TYPE;        --顧客法人情報存在確認用変数
    lv_customer_class        VARCHAR2(100)   := NULL;                     --ローカル変数・顧客区分
    lv_cust_class_mst        hz_cust_accounts.customer_class_code%TYPE;   --顧客区分存在確認用変数
    lv_customer_name         VARCHAR2(500)   := NULL;                     --ローカル変数・顧客名称
    lv_cust_name_kana        VARCHAR2(500)   := NULL;                     --ローカル変数・顧客名称カナ
    lv_cust_name_ryaku       VARCHAR2(500)   := NULL;                     --ローカル変数・略称
    lv_customer_status       VARCHAR2(100)   := NULL;                     --ローカル変数・顧客ステータス
    lv_approval_reason       VARCHAR2(100)   := NULL;                     --ローカル変数・中止理由
    lv_appr_reason_mst       VARCHAR2(100)   := NULL;                     --ローカル変数・中止理由
    lv_approval_date         VARCHAR2(100)   := NULL;                     --ローカル変数・中止決済日
    lv_ar_invoice_code       VARCHAR2(100)   := NULL;                     --ローカル変数・売掛コード１（請求書）
    lv_ar_invoice_code_mst   VARCHAR2(100)   := NULL;                     --売掛コード１（請求書）存在確認用変数
    lv_ar_location_code      VARCHAR2(100)   := NULL;                     --ローカル変数・売掛コード２（事業所）
    lv_ar_others_code        VARCHAR2(100)   := NULL;                     --ローカル変数・売掛コード３（その他）
    lv_invoice_class         VARCHAR2(100)   := NULL;                     --ローカル変数・請求書発行区分
    lv_invoice_class_mst     VARCHAR2(100)   := NULL;                     --請求書発行区分存在確認用変数
    lv_invoice_cycle         VARCHAR2(100)   := NULL;                     --ローカル変数・請求書発行サイクル
    lv_invoice_cycle_mst     VARCHAR2(100)   := NULL;                     --請求書発行サイクル存在確認用変数
    lv_invoice_form          VARCHAR2(100)   := NULL;                     --ローカル変数・請求書出力形式
    lv_invoice_form_mst      VARCHAR2(100)   := NULL;                     --請求書出力形式存在確認用変数
    lv_payment_term_id       VARCHAR2(100)   := NULL;                     --ローカル変数・支払条件
    lv_payment_term_id_mst   VARCHAR2(100)   := NULL;                     --支払条件存在確認用変数
    lv_payment_term_second   VARCHAR2(100)   := NULL;                     --ローカル変数・第2支払条件
    lv_payment_second_mst    VARCHAR2(100)   := NULL;                     --第2支払条件存在確認用変数
    lv_payment_term_third    VARCHAR2(100)   := NULL;                     --ローカル変数・第3支払条件
    lv_payment_third_mst     VARCHAR2(100)   := NULL;                     --第3支払条件存在確認用変数
    lv_sales_chain_code      VARCHAR2(100)   := NULL;                     --ローカル変数・チェーン店コード（販売先）
    lv_sales_chain_code_mst  VARCHAR2(100)   := NULL;                     --チェーン店コード（販売先）存在確認用変数
    lv_delivery_chain_code   VARCHAR2(100)   := NULL;                     --ローカル変数・チェーン店コード（納品先）
    lv_deliv_chain_code_mst  VARCHAR2(100)   := NULL;                     --チェーン店コード（販売先）存在確認用変数
    lv_policy_chain_code     VARCHAR2(100)   := NULL;                     --ローカル変数・チェーン店コード（政策用）
    lv_edi_chain_code        VARCHAR2(100)   := NULL;                     --ローカル変数・チェーン店コード（ＥＤＩ）
    lv_edi_chain_mst         VARCHAR2(100)   := NULL;                     --チェーン店コード（ＥＤＩ）存在確認用変数
    lv_store_code            VARCHAR2(100)   := NULL;                     --ローカル変数・店舗コード
    lv_postal_code           VARCHAR2(100)   := NULL;                     --ローカル変数・郵便番号
    lv_state                 VARCHAR2(100)   := NULL;                     --ローカル変数・都道府県
    lv_city                  VARCHAR2(100)   := NULL;                     --ローカル変数・市・区
    lv_address1              VARCHAR2(500)   := NULL;                     --ローカル変数・住所1
    lv_address2              VARCHAR2(500)   := NULL;                     --ローカル変数・住所2
    lv_address3              VARCHAR2(500)   := NULL;                     --ローカル変数・地区コード
    lv_cust_chiku_code_mst   VARCHAR2(100)   := NULL;                     --地区コード存在確認用変数
    lv_credit_limit          VARCHAR2(100)   := NULL;                     --ローカル変数・与信限度額（文字）
    ln_credit_limit          NUMBER          := NULL;                     --ローカル変数・与信限度額（数値）
    lv_decide_div            VARCHAR2(100)   := NULL;                     --ローカル変数・判定区分
    lv_decide_div_mst        VARCHAR2(100)   := NULL;                     --判定区分存在確認用変数
--
    lv_cust_status_mst       hz_parties.duns_number_c%TYPE;               --顧客ステータス存在確認用変数
    lv_get_cust_status       hz_parties.duns_number_c%TYPE;               --顧客ステータス現行取得用変数
--
    lv_business_low_type     VARCHAR2(100)   := NULL;                     --ローカル変数・小分類
    lv_business_low_mst      xxcmm_cust_accounts.business_low_type%TYPE;  --小分類存在確認用変数
-- 2010/02/15 Ver1.5 E_本稼動01582 add start by Yutaka.Kuboshima
-- Ver1.10 del start
--    lv_business_low_type_now xxcmm_cust_accounts.business_low_type%TYPE;  --現在設定されている小分類
-- Ver1.10 del end
-- 2010/02/15 Ver1.5 E_本稼動01582 add end by Yutaka.Kuboshima
--
    lv_check_status          VARCHAR2(1)     := NULL;                     --項目チェック結果格納用変数
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    lv_cust_customer_class      VARCHAR2(100)   := NULL;                  --ローカル変数・顧客区分(顧客マスタ)
    lv_invoice_required_flag    VARCHAR2(1)     := NULL;                  --ローカル変数・請求書用コード必須フラグ
    lv_invoice_code             VARCHAR2(100)   := NULL;                  --ローカル変数・請求書用コード
-- Ver1.27 add start
    lv_invoice_tax_div          VARCHAR2(100)   := NULL;                  --ローカル変数・請求書消費税積上げ計算方式
-- Ver1.27 add end
    ln_invoice_code_mst         hz_cust_accounts.cust_account_id%TYPE;    --請求書用コード確認用変数
    lv_industry_div             VARCHAR2(100)   := NULL;                  --ローカル変数・業種
    lv_industry_div_mst         VARCHAR2(100)   := NULL;                  --業種確認用変数
    lv_bill_base_code           VARCHAR2(100)   := NULL;                  --ローカル変数・請求拠点
    lv_bill_base_code_mst       VARCHAR2(100)   := NULL;                  --請求拠点確認用変数
    lv_receiv_base_code         VARCHAR2(100)   := NULL;                  --ローカル変数・入金拠点
    lv_receiv_base_code_mst     VARCHAR2(100)   := NULL;                  --入金拠点確認用変数
    lv_delivery_base_code       VARCHAR2(100)   := NULL;                  --ローカル変数・納品拠点
    lv_delivery_base_code_mst   VARCHAR2(100)   := NULL;                  --納品拠点確認用変数
    lv_selling_transfer_div     VARCHAR2(100)   := NULL;                  --ローカル変数・売上実績振替
    lv_selling_transfer_div_mst VARCHAR2(100)   := NULL;                  --売上実績振替確認用変数
    lv_card_company             VARCHAR2(100)   := NULL;                  --ローカル変数・カード会社
    lv_card_company_mst         VARCHAR2(100)   := NULL;                  --カード会社確認用変数
    lv_wholesale_ctrl_code      VARCHAR2(100)   := NULL;                  --ローカル変数・問屋管理コード
    lv_wholesale_ctrl_code_mst  VARCHAR2(100)   := NULL;                  --問屋管理コード確認用変数
    lv_price_list               VARCHAR2(500)   := NULL;                  --ローカル変数・価格表
    lv_price_list_mst           qp_list_headers_b.list_header_id%TYPE;    --価格表確認用変数
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
    lv_period_status            VARCHAR2(1)     := NULL;                  --ローカル変数・会計期間クローズステータス
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
    lv_ship_storage_code        VARCHAR2(100)   := NULL;                  --ローカル変数・出荷元保管場所
    lv_ship_storage_code_mst    VARCHAR2(100)   := NULL;                  --出荷元保管場所
    ln_item_num                 NUMBER;                                   --CSV項目数
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
    lv_delivery_order           VARCHAR2(100)   := NULL;                  --ローカル変数・配送順（EDI）
    lv_edi_district_code        VARCHAR2(100)   := NULL;                  --ローカル変数・EDI地区コード（EDI）
    lv_edi_district_name        VARCHAR2(100)   := NULL;                  --ローカル変数・EDI地区名（EDI）
    lv_edi_district_kana        VARCHAR2(100)   := NULL;                  --ローカル変数・EDI地区名カナ（EDI）
    lv_tsukagatazaiko_div       VARCHAR2(100)   := NULL;                  --ローカル変数・通過在庫型区分（EDI）
    lv_tsukagatazaiko_div_mst   xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;  --通過在庫型区分（EDI）確認用変数
    lv_deli_center_code         VARCHAR2(100)   := NULL;                  --ローカル変数・EDI納品センターコード
    lv_deli_center_name         VARCHAR2(100)   := NULL;                  --ローカル変数・EDI納品センター名
    lv_edi_forward_number       VARCHAR2(100)   := NULL;                  --ローカル変数・EDI伝送追番
    lv_cust_store_name          VARCHAR2(100)   := NULL;                  --ローカル変数・顧客店舗名称
    lv_torihikisaki_code        VARCHAR2(100)   := NULL;                  --ローカル変数・取引先コード
    lv_tsukagatazaiko_flag      VARCHAR2(1)     := NULL;                  --通過在庫型区分（EDI）入力チェック用
    lv_chain_store_db           xxcmm_cust_accounts.chain_store_code%TYPE;    --顧客追加情報存在確認用変数
    lv_tsukagatazaiko_div_db    xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;  --顧客追加情報存在確認用変数
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
    lv_vist_target_div          VARCHAR2(100)   := NULL;                  --ローカル変数・訪問対象区分
    lv_vist_target_div_mst      xxcmm_cust_accounts.vist_target_div%TYPE; --訪問対象区分確認用変数
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
    lv_cnvs_base_code           VARCHAR2(100)   := NULL;                  --ローカル変数・獲得拠点コード
    lv_cnvs_base_code_mst1       xxcmm_cust_accounts.cnvs_base_code%TYPE; --獲得拠点コード確認用変数1
    lv_cnvs_base_code_mst2       xxcmm_cust_accounts.cnvs_base_code%TYPE; --獲得拠点コード確認用変数2
    lv_cnvs_business_person     VARCHAR2(100)   := NULL;                  --ローカル変数・獲得営業員
    lv_cnvs_business_person_mst1 xxcmm_cust_accounts.cnvs_business_person%TYPE;  --獲得営業員確認用変数1
    lv_cnvs_business_person_mst2 xxcmm_cust_accounts.cnvs_business_person%TYPE;  --獲得営業員確認用変数2
    lv_base_code_flag1          VARCHAR2(1)     := NULL;                  --獲得拠点コード入力チェック用1
    lv_business_person_flag1    VARCHAR2(1)     := NULL;                  --獲得営業員入力チェック用1
    lv_base_code_flag2          VARCHAR2(1)     := NULL;                  --獲得拠点コード入力チェック用2
    lv_business_person_flag2    VARCHAR2(1)     := NULL;                  --獲得営業員入力チェック用2
    lv_base_code_flag3          VARCHAR2(1)     := NULL;                  --獲得拠点コード入力チェック用3
    lv_business_person_flag3    VARCHAR2(1)     := NULL;                  --獲得営業員入力チェック用3
    lv_base_code_flag4          VARCHAR2(1)     := NULL;                  --獲得拠点コード入力チェック用4
    lv_business_person_flag4    VARCHAR2(1)     := NULL;                  --獲得営業員入力チェック用4
    lv_new_point_div            VARCHAR2(1)     := NULL;                  --ローカル変数・新規ポイント区分
    lv_new_point_div_mst        xxcmm_cust_accounts.new_point_div%TYPE;   --新規ポイント区分確認用変数
    lv_new_point                VARCHAR2(100)   := NULL;                  --ローカル変数・新規ポイント
    ln_new_point                NUMBER          := NULL;                  --ローカル変数・新規ポイント(数値)
    lv_intro_base_code          VARCHAR2(100)   := NULL;                  --ローカル変数・紹介拠点コード
    lv_intro_base_code_mst1     xxcmm_cust_accounts.intro_base_code%TYPE; --紹介拠点コード確認用変数1
    lv_intro_base_code_mst2     xxcmm_cust_accounts.intro_base_code%TYPE; --紹介拠点コード確認用変数2
    lv_intro_business_person    VARCHAR2(100)   := NULL;                  --ローカル変数・紹介営業員
    lv_intro_business_person_mst1 xxcmm_cust_accounts.intro_business_person%TYPE; --紹介営業員確認用変数1
    lv_intro_business_person_mst2 xxcmm_cust_accounts.intro_business_person%TYPE; --紹介営業員確認用変数2
    lv_int_bus_per_flag1        VARCHAR2(1)     := NULL;                  --紹介営業員チェック用1
    lv_int_bus_per_flag2        VARCHAR2(1)     := NULL;                  --紹介営業員チェック用2
    lv_base_code                VARCHAR2(100)   := NULL;                  --ローカル変数・本部担当拠点
    lv_base_code_mst            xxcmm_mst_corporate.base_code%TYPE;       --紹介営業員確認用変数1
    lv_tdb_code                 VARCHAR2(100)   := NULL;                  --ローカル変数・TDBコード
    lv_corp_approval_date       VARCHAR2(100)   := NULL;                  --ローカル変数・決裁日付
    lv_intro_chain_code1        VARCHAR2(100)   := NULL;                  --ローカル変数・紹介者チェーンコード１
    lv_intro_chain_code2        VARCHAR2(100)   := NULL;                  --ローカル変数・控除用チェーンコード
--Ver1.25 add start
    lt_intro_chain_code2_bef    xxcmm_cust_accounts.intro_chain_code2%TYPE;     -- 現在値・控除用チェーンコード
--Ver1.25 add end
    lv_sales_head_base_code     VARCHAR2(100)   := NULL;                  --ローカル変数・販売先本部担当拠点
    lv_sales_head_base_code_mst xxcmm_cust_accounts.sales_head_base_code%TYPE; --販売先本部担当拠点確認用変数
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
    lt_business_low_type_bef    xxcmm_cust_accounts.business_low_type%TYPE;     --現在値・業態(小分類)
    lt_business_low_type_aft    xxcmm_cust_accounts.business_low_type%TYPE;     --更新値・業態(小分類)
    lt_sell_trans_div_bef       xxcmm_cust_accounts.selling_transfer_div%TYPE;  --現在値・売上実績振替
    lt_sell_trans_div_aft       xxcmm_cust_accounts.selling_transfer_div%TYPE;  --更新値・売上実績振替
    lt_tsukagatazaiko_div_bef   xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;    --現在値・通過在庫型区分
    lt_tsukagatazaiko_div_aft   xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;    --更新値・通過在庫型区分
    lt_ship_storage_code_bef    xxcmm_cust_accounts.ship_storage_code%TYPE;     --現在値・出荷元保管場所
    lt_ship_storage_code_aft    xxcmm_cust_accounts.ship_storage_code%TYPE;     --更新値・出荷元保管場所
    lt_ship_storage_code_mst    xxcmm_cust_accounts.ship_storage_code%TYPE;     --出荷元保管場所確認用変数
    lt_chain_store_code_bef     xxcmm_cust_accounts.chain_store_code%TYPE;      --現在値・チェーン店コード(EDI)
    lt_chain_store_code_aft     xxcmm_cust_accounts.chain_store_code%TYPE;      --更新値・チェーン店コード(EDI)
    lt_chain_store_code_mst     xxcmm_cust_accounts.chain_store_code%TYPE;      --チェーン店コード(EDI)確認用変数
    lt_delivery_base_code_bef   xxcmm_cust_accounts.delivery_base_code%TYPE;    --現在値・納品拠点
    lt_delivery_base_code_aft   xxcmm_cust_accounts.delivery_base_code%TYPE;    --更新値・納品拠点
    lv_sale_base_code           VARCHAR2(100)   := NULL;                        --ローカル変数・売上拠点
    lt_sale_base_code_aft       xxcmm_cust_accounts.sale_base_code%TYPE;        --更新値・売上拠点
    lv_address_lines_phonetic   VARCHAR2(500)   := NULL;                        --ローカル変数・電話番号
    lv_address4                 VARCHAR2(500)   := NULL;                        --ローカル変数・FAX
    lv_tax_div                  VARCHAR2(100)   := NULL;                        --ローカル変数・消費税区分
    lt_tax_div_aft              xxcmm_cust_accounts.tax_div%TYPE;               --更新値・消費税区分
    lv_longitude                VARCHAR2(100)   := NULL;                        --ローカル変数・ピークカット開始時刻
    lt_longitude_bef            xxcmm_cust_accounts.longitude%TYPE;             --現在値・ピークカット開始時刻
    lt_longitude_aft            xxcmm_cust_accounts.longitude%TYPE;             --更新値・ピークカット開始時刻
    lv_rate                     VARCHAR2(100)   := NULL;                        --ローカル変数・消化計算用掛率
    lt_rate_bef                 xxcmm_cust_accounts.rate%TYPE;                  --現在値・消化計算用掛率
    lv_rcv_dsct_rate            VARCHAR2(100)   := NULL;                        --ローカル変数・入金値引率
    lv_conclusion_day1          VARCHAR2(100)   := NULL;                        --ローカル変数・消化計算締め日1
    lt_conclusion_day1_bef      xxcmm_cust_accounts.conclusion_day1%TYPE;       --現在値・消化計算締め日1
    lt_conclusion_day1_aft      xxcmm_cust_accounts.conclusion_day1%TYPE;       --更新値・消化計算締め日1
    lv_conclusion_day2          VARCHAR2(100)   := NULL;                        --ローカル変数・消化計算締め日2
    lt_conclusion_day2_bef      xxcmm_cust_accounts.conclusion_day2%TYPE;       --現在値・消化計算締め日2
    lt_conclusion_day2_aft      xxcmm_cust_accounts.conclusion_day2%TYPE;       --更新値・消化計算締め日2
    lv_conclusion_day3          VARCHAR2(100)   := NULL;                        --ローカル変数・消化計算締め日3
    lt_conclusion_day3_bef      xxcmm_cust_accounts.conclusion_day3%TYPE;       --現在値・消化計算締め日3
    lt_conclusion_day3_aft      xxcmm_cust_accounts.conclusion_day3%TYPE;       --更新値・消化計算締め日3
    lv_calendar_code            VARCHAR2(100)   := NULL;                        --ローカル変数・稼働日カレンダ
    lt_calendar_code_aft        xxcmm_cust_accounts.calendar_code%TYPE;         --更新値・稼働日カレンダ
    lv_store_cust_code          VARCHAR2(100)   := NULL;                        --ローカル変数・店舗営業用顧客コード
    lt_store_cust_code_aft      xxcmm_cust_accounts.store_cust_code%TYPE;       --更新値・店舗営業用顧客コード
    --妥当性チェックフラグ
    lb_bz_low_type_chk_flg      BOOLEAN         DEFAULT TRUE;    --業態(小分類)チェックフラグ
    lb_sell_trans_chk_flg       BOOLEAN         DEFAULT TRUE;    --売上実績振替チェックフラグ
    lb_db_code_chk_flg          BOOLEAN         DEFAULT TRUE;    --納品拠点チェックフラグ
    lb_tsukazaiko_chk_flg       BOOLEAN         DEFAULT TRUE;    --通過在庫型区分チェックフラグ
    lb_sp_strg_code_chk_flg     BOOLEAN         DEFAULT TRUE;    --出荷元保管場所チェックフラグ
    lb_cs_code_chk_flg          BOOLEAN         DEFAULT TRUE;    --チェーン店コード(EDI)チェックフラグ
    lb_conc_day_chk_flg         BOOLEAN         DEFAULT TRUE;    --消化計算締め日チェックフラグ
-- Ver1.10 add end
-- Ver1.12 add start
    lt_invoice_form_bef         hz_cust_site_uses.attribute7%TYPE;              --現在値・請求書出力形式
    lt_invoice_form_aft         hz_cust_site_uses.attribute7%TYPE;              --更新値・請求書出力形式
    lt_invoice_cycle_bef        hz_cust_site_uses.attribute8%TYPE;              --現在値・請求書発行サイクル
    lt_invoice_cycle_aft        hz_cust_site_uses.attribute8%TYPE;              --更新値・請求書発行サイクル
    lb_invoice_chk_flg          BOOLEAN         DEFAULT TRUE;                   --請求書関連チェックフラグ
-- Ver1.12 add end
-- Ver1.14 add start
    lv_esm_target_div           VARCHAR2(1)     := NULL;                        --ローカル変数・ストレポ＆商談くん連携対象フラグ
    lt_esm_target_div_mst       xxcmm_cust_accounts.esm_target_div%TYPE;        --ストレポ＆商談くん連携対象フラグ確認用変数
-- Ver1.14 add end
-- Ver1.15 add start
    lt_invoice_code_bef         xxcmm_cust_accounts.invoice_code%TYPE;          --現在値・請求書用コード
    lt_invoice_code_aft         xxcmm_cust_accounts.invoice_code%TYPE;          --更新値・請求書用コード
    lt_invoice_class_bef        xxcmm_cust_accounts.invoice_printing_unit%TYPE; --現在値・請求書印刷単位
    lt_invoice_class_aft        xxcmm_cust_accounts.invoice_printing_unit%TYPE; --更新値・請求書印刷単位
    lv_invoice_trust_flag       VARCHAR2(1)     := NULL;                        --ローカル変数・業者委託時設定可否フラグ
-- Ver1.15 add end
-- Ver1.16 add start
    lt_offset_cust_div          xxcmm_cust_accounts.offset_cust_div%TYPE;       --相殺用顧客区分確認用変数
    lv_offset_cust_code         VARCHAR2(30)    := NULL;                        --ローカル変数・相殺用顧客コード
    lt_offset_cust_code_mst     xxcmm_cust_accounts.offset_cust_code%TYPE;      --相殺用顧客コード確認用変数
    lt_offset_cust_code_bef     xxcmm_cust_accounts.offset_cust_code%TYPE;      --現在値・相殺用顧客コード
    lt_offset_cust_code_aft     xxcmm_cust_accounts.offset_cust_code%TYPE;      --更新値・相殺用顧客コード
    lv_bp_customer_code         VARCHAR2(100)   := NULL;                        --ローカル変数・取引先顧客コード
    lt_bp_customer_code_bef     xxcmm_cust_accounts.bp_customer_code%TYPE;      --現在値・取引先顧客コード
    lt_bp_customer_code_aft     xxcmm_cust_accounts.bp_customer_code%TYPE;      --更新値・取引先顧客コード
    lb_offset_cust_chk_flg      BOOLEAN         DEFAULT TRUE;                   --相殺用顧客関連チェックフラグ
    lv_bp_cust_exists           VARCHAR2(9)     := NULL;                        --取引先顧客コード重複チェック用変数
-- Ver1.16 add end
-- Ver1.19 add start
    lv_latitude                 VARCHAR2(20)    := NULL;                        --ローカル変数・カテゴリー商品計上区分
    lt_latitude_bef             xxcmm_cust_accounts.latitude%TYPE;              --現在値・カテゴリー商品計上区分
    lt_latitude_mst             xxcmm_cust_accounts.latitude%TYPE;              --LOOKUP確認用・カテゴリー商品計上区分
    ln_cnt                      NUMBER          := NULL;                        --カテゴリー商品計上区分不要対象件数
-- Ver1.19 add end
-- Ver1.23 add start
    lv_dedu_chain_code          VARCHAR2(30)    := NULL;                        --控除用チェーンコード
    lv_dedu_chain_code_mst      VARCHAR2(100)   := NULL;                        --控除用チェーンコード存在確認用変数
-- Ver1.23 add end
--Ver1.25 add start
    lv_recon_slip_num           VARCHAR2(2000)  := NULL;                        --控除消込ヘッダー情報の消込ステータスチェック用支払伝票番号変数
--Ver1.25 add end
-- Ver1.26 add start
    ln_base_code_business_cnt   NUMBER          := 0;                           --所属拠点（事務センター）のカウント
-- Ver1.26 add end
-- Ver1.28 add start
    lv_pos_enterprise_code      VARCHAR2(100)   := NULL;                        --ローカル変数・POS企業コード
    lv_pos_store_code           VARCHAR2(100)   := NULL;                        --ローカル変数・POS店舗コード
    lt_pos_enterprise_code      xxcmm_cust_accounts.pos_enterprise_code%TYPE;   --現在値・POS企業コード
    lt_pos_store_code           xxcmm_cust_accounts.pos_store_code%TYPE;        --現在値・POS店舗コード
-- Ver1.28 add end
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- アップロードファイル存在確認カーソル
    CURSOR check_upload_file_cur(
      in_file_id  IN NUMBER,
      iv_format   IN VARCHAR2)
    IS
      SELECT xmf.file_name  file_name
      FROM   xxccp_mrp_file_ul_interface  xmf
      WHERE  xmf.file_id           = in_file_id
      AND    xmf.file_content_type = iv_format
      ;
    -- アップロードファイル存在確認カーソルレコード型
    check_upload_file_rec  check_upload_file_cur%ROWTYPE;
--
    -- 顧客コード存在確認カーソル
    CURSOR check_cust_code_cur(
      iv_cust_code IN VARCHAR2)
    IS
      SELECT hca.cust_account_id  cust_id,
             hca.account_number   cust_code,
             hca.party_id         party_id,
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
             hca.customer_class_code cust_kbn
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
      FROM   hz_cust_accounts     hca
      WHERE  hca.account_number = iv_cust_code
      ;
    -- 顧客コード存在確認カーソルレコード型
    check_cust_code_rec  check_cust_code_cur%ROWTYPE;
--
    -- 顧客追加情報存在確認カーソル
    CURSOR check_cust_addon_cur(
      in_cust_id  IN NUMBER)
    IS
      SELECT xca.customer_id      customer_id
      FROM   xxcmm_cust_accounts  xca
      WHERE  xca.customer_id    = in_cust_id
      ;
    -- 顧客追加情報存在確認カーソルレコード型
    check_cust_addon_rec  check_cust_addon_cur%ROWTYPE;
--
    -- 顧客法人情報存在確認カーソル
    CURSOR check_cust_corp_cur(
      in_cust_id  IN NUMBER)
    IS
      SELECT xmc.customer_id      customer_id
      FROM   xxcmm_mst_corporate  xmc
      WHERE  xmc.customer_id    = in_cust_id
      ;
    -- 顧客法人情報存在確認カーソルレコード型
    check_cust_corp_rec  check_cust_corp_cur%ROWTYPE;
--
    -- 顧客区分チェックカーソル
    CURSOR check_cust_class_cur(
      iv_cust_class IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_customer_class
      AND    flvv.lookup_code = iv_cust_class
      ;
    -- 顧客区分チェックカーソルレコード型
    check_cust_class_rec  check_cust_class_cur%ROWTYPE;
--
    -- 業態（小分類）チェックカーソル
    CURSOR check_business_low_cur(
      iv_business_low_type IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      business_low_type
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_business_low_type
      AND    flvv.lookup_code = iv_business_low_type
      ;
    -- 業態（小分類）チェックカーソルレコード型
    check_business_low_rec  check_business_low_cur%ROWTYPE;
--
    -- 顧客ステータスチェックカーソル
    CURSOR check_cust_status_cur(
      iv_cust_status IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_status
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_customer_status
      AND    flvv.lookup_code = iv_cust_status
      ;
    -- 顧客ステータスチェックカーソルレコード型
    check_cust_status_rec  check_cust_status_cur%ROWTYPE;
--
    -- 顧客ステータス取得カーソル
    CURSOR get_cust_status_cur(
      in_paty_id IN NUMBER)
    IS
      SELECT duns_number_c  cust_status
      FROM   hz_parties     hp
      WHERE  hp.party_id = in_paty_id
      ;
    -- 顧客ステータス取得カーソルレコード型
    get_cust_status_rec  get_cust_status_cur%ROWTYPE;
--
    -- 中止理由チェックカーソル
    CURSOR check_approval_reason_cur(
      iv_approval_reason IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      approval_reason
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_approval_reason
      AND    flvv.lookup_code = iv_approval_reason
      ;
    -- 中止理由チェックカーソルレコード型
    check_approval_reason_rec  check_approval_reason_cur%ROWTYPE;
--
    -- 売掛コード１（請求書）チェックカーソル
    CURSOR check_ar_invoice_code_cur(
      iv_ar_invoice_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      ar_invoice_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_ar_invoice_code
      AND    flvv.lookup_code = iv_ar_invoice_code
      ;
    -- 売掛コード１（請求書）チェックカーソルレコード型
    check_ar_invoice_code_rec  check_ar_invoice_code_cur%ROWTYPE;
--
    -- 請求書印刷単位チェックカーソル
    CURSOR check_invoice_class_cur(
      iv_invoice_class IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_class
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
            ,flvv.attribute1       required_flag
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- Ver1.15 add start
            ,flvv.attribute3       trust_flag
-- Ver1.15 add end
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_class
      AND    flvv.lookup_code = iv_invoice_class
      ;
    -- 請求書印刷単位チェックカーソルレコード型
    check_invoice_class_rec  check_invoice_class_cur%ROWTYPE;
--
    -- 請求書発行サイクルチェックカーソル
    CURSOR check_invoice_cycle_cur(
      iv_invoice_cycle IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_cycle
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_issue_cycle
      AND    flvv.lookup_code = iv_invoice_cycle
      ;
    -- 請求書発行サイクルチェックカーソルレコード型
    check_invoice_cycle_rec  check_invoice_cycle_cur%ROWTYPE;
--
    -- 請求書出力形式チェックカーソル
    CURSOR check_invoice_form_cur(
      iv_invoice_form IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_form
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_form
      AND    flvv.lookup_code = iv_invoice_form
      ;
    -- 請求書出力形式チェックカーソルレコード型
    check_invoice_form_rec  check_invoice_form_cur%ROWTYPE;
--
    -- 支払条件チェックカーソル
    CURSOR check_payment_term_cur(
      iv_payment_term IN VARCHAR2)
    IS
      SELECT rt.name   payment_term_id
      FROM   ra_terms  rt
      WHERE  rt.name   = iv_payment_term
      AND    ROWNUM    = 1
      ;
    -- 支払条件チェックカーソルレコード型
    check_payment_term_rec  check_payment_term_cur%ROWTYPE;
--
    -- チェーン店コード（販売先）チェックカーソル
    CURSOR check_chain_code_cur(
      iv_chain_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      chain_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_xxcmm_chain_code
      AND    flvv.lookup_code = iv_chain_code
      ;
    -- チェーン店コード（販売先）チェックカーソルレコード型
    check_chain_code_rec  check_chain_code_cur%ROWTYPE;
--
    -- チェーン店コード（ＥＤＩ）チェックカーソル
    CURSOR check_edi_chain_cur(
      iv_edi_chain_code IN VARCHAR2)
    IS
      SELECT xca.edi_chain_code   edi_chain_code
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.customer_class_code = cv_edi_class
      AND    hca.cust_account_id     = xca.customer_id
      AND    xca.edi_chain_code      = iv_edi_chain_code
      AND    ROWNUM = 1
      ;
    -- チェーン店コード（ＥＤＩ）チェックカーソルレコード型
    check_edi_chain_rec  check_edi_chain_cur%ROWTYPE;
--
    -- 地区コードチェックカーソル
    CURSOR check_cust_chiku_code_cur(
      iv_cust_chiku_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_chiku_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_cust_chiku_code
      AND    flvv.lookup_code = iv_cust_chiku_code
      ;
    -- 地区コードチェックカーソルレコード型
    check_cust_chiku_code_rec  check_cust_chiku_code_cur%ROWTYPE;
--
    -- 判定区分チェックカーソル
    CURSOR check_decide_div_cur(
      iv_decide_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      decide_div
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_decide_div
      AND    flvv.lookup_code = iv_decide_div
      ;
    -- 判定区分チェックカーソルレコード型
    check_decide_div_rec  check_decide_div_cur%ROWTYPE;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- 請求書用コードチェックカーソル
    CURSOR check_invoice_code_cur(
      iv_invoice_code IN VARCHAR2)
    IS
      SELECT hca.cust_account_id cust_id
      FROM   hz_cust_accounts hca
      WHERE  hca.customer_class_code = cv_seikyusho_kbn
      AND    hca.account_number      = iv_invoice_code
      ;
    -- 請求書用コードチェックカーソルレコード型
    check_invoice_code_rec  check_invoice_code_cur%ROWTYPE;
--
    -- 参照タイプチェックカーソル
    CURSOR check_lookup_type_cur(
      iv_lookup_code IN VARCHAR2
     ,iv_lookup_type IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      lookup_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = iv_lookup_type
      AND    flvv.lookup_code = iv_lookup_code
      ;
    -- 参照タイプチェックカーソルレコード型
    check_lookup_type_rec  check_lookup_type_cur%ROWTYPE;
--
    -- 値セットチェックカーソル
    CURSOR check_flex_value_cur(
      iv_flex_value IN VARCHAR2)
    IS
      SELECT ffv.flex_value      flex_value
      FROM   fnd_flex_value_sets ffvs
            ,fnd_flex_values     ffv
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_aff_dept
      AND    ffv.summary_flag         = cv_no
      AND    ffv.flex_value           = iv_flex_value
      ;
    -- 値セットチェックカーソルレコード型
    check_flex_value_rec  check_flex_value_cur%ROWTYPE;
--
    -- カード会社チェックカーソル
    CURSOR check_card_company_cur(
      iv_card_company IN VARCHAR2)
    IS
      SELECT hca.cust_account_id cust_id
      FROM   hz_cust_accounts hca
            ,xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.customer_class_code = cv_urikake_kbn
      AND    xca.card_company_div    = cv_card_company_div
      AND    hca.account_number      = iv_card_company
      ;
    -- カード会社チェックレコード型
    check_card_company_rec  check_card_company_cur%ROWTYPE;
--
    -- 価格表チェックカーソル
    CURSOR check_price_list_cur(
      iv_price_list IN VARCHAR2)
    IS
      SELECT qlhb.list_header_id list_header_id
      FROM   qp_list_headers_tl  qlht
            ,qp_list_headers_b   qlhb
      WHERE  qlht.list_header_id    = qlhb.list_header_id
      AND    qlht.source_lang       = cv_language_ja
      AND    qlht.language          = cv_language_ja
      AND    qlhb.orig_org_id       = fnd_global.org_id
      AND    qlhb.list_type_code    = cv_list_type_prl
      AND    gd_process_date BETWEEN NVL(qlhb.start_date_active, gd_process_date)
                                 AND NVL(qlhb.end_date_active, gd_process_date)
      AND    qlht.name              = iv_price_list
      ;
    -- 価格表チェックレコード型
    check_price_list_rec  check_price_list_cur%ROWTYPE;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
    -- 会計期間クローズステータス取得カーソル
    CURSOR get_period_status_cur(
      id_stop_approval_date IN DATE)
    IS
      SELECT gps.closing_status period_status
      FROM   gl_periods         gp      -- 会計カレンダ
            ,gl_period_statuses gps     -- 会計カレンダステータス
      WHERE  EXISTS( -- ARアプリケーションのカレンダを抽出
                     SELECT 'X'
                     FROM   fnd_application   fa
                     WHERE  fa.application_id         = gps.application_id
                       AND  fa.application_short_name = cv_apl_short_nm_ar
             )
      AND    EXISTS( -- 営業システム会計帳簿IDのカレンダを抽出
                     SELECT 'X'
                     FROM   gl_sets_of_books  gsob
                     WHERE  gsob.set_of_books_id  = gps.set_of_books_id
                       AND  gsob.name             = gv_ar_set_of_books
             )
      AND    gp.period_name              = gps.period_name
      AND    gp.period_set_name          = gv_gl_cal_code
      AND    gp.adjustment_period_flag   = cv_no
      AND    gps.adjustment_period_flag  = cv_no
      AND    id_stop_approval_date BETWEEN gps.start_date AND gps.end_date
      ;
    -- 会計期間クローズステータス取得レコード型
    get_period_status_rec  get_period_status_cur%ROWTYPE;
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/02/15 Ver1.5 E_本稼動_01582 add start by Yutaka.Kuboshima
    -- 業態(小分類)取得カーソル
    CURSOR get_business_low_type_cur(
      in_cust_id IN NUMBER)
    IS
    SELECT xca.business_low_type business_low_type
    FROM   xxcmm_cust_accounts xca
    WHERE  xca.customer_id = in_cust_id
    ;
    -- 業態(小分類)取得レコード型
    get_business_low_type_rec get_business_low_type_cur%ROWTYPE;
-- 2010/02/15 Ver1.5 E_本稼動_01582 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
    -- 出荷元保管場所チェックカーソル
    CURSOR check_ship_storage_code_cur(
      iv_ship_storage_code IN VARCHAR2)
    IS
      SELECT msi.secondary_inventory_name secondary_inventory_name
      FROM   mtl_secondary_inventories msi
            ,mtl_parameters            mp
      WHERE  msi.organization_id          = mp.organization_id
        AND  mp.organization_code         = gv_organization_code
        AND  msi.secondary_inventory_name = iv_ship_storage_code
      ;
    -- 出荷元保管場所チェックレコード
    check_ship_storage_code_rec check_ship_storage_code_cur%ROWTYPE;
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
    -- 顧客追加情報チェックカーソル
    CURSOR check_db_customer_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.chain_store_code     chain_store_code
            ,xca.tsukagatazaiko_div   tsukagatazaiko_div
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- 顧客追加情報チェックカーソルレコード型
    check_db_customer_rec  check_db_customer_cur%ROWTYPE;
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
    -- 訪問対象区分チェックカーソル
    CURSOR check_homon_taisyo_kbn_cur(
      iv_vist_target_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      homon_taisyo_kbn
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_homon_taisyo_kbn
      AND    flvv.lookup_code = iv_vist_target_div
      ;
    -- 訪問対象区分チェックカーソルレコード型
    check_homon_taisyo_kbn_rec  check_homon_taisyo_kbn_cur%ROWTYPE;
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
    -- 獲得拠点コード、営業員チェックカーソル
    CURSOR check_db_code_person_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.cnvs_base_code         cnvs_base_code
            ,xca.cnvs_business_person   cnvs_business_person
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- 獲得拠点コード、営業員チェックカーソルレコード型
    check_db_code_person_rec  check_db_code_person_cur%ROWTYPE;
--
    -- 獲得営業員と拠点コードの紐付きチェックカーソル
    CURSOR check_db_person_relation_cur(
      iv_business_person IN VARCHAR2)
    IS
      SELECT paa.ass_attribute5   new_base_code
      FROM   per_all_people_f pap            -- 従業員マスタ
            ,per_all_assignments_f paa       -- アサインメントマスタ
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    pap.employee_number = iv_business_person
      ;
    -- 獲得営業員と拠点コードの紐付きチェックカーソルレコード型
    check_db_person_relation_rec  check_db_person_relation_cur%ROWTYPE;
--
    -- 獲得営業員と拠点コードの紐付き権限用チェックカーソル
    CURSOR check_db_person_rel_auth_cur(
      iv_business_person IN VARCHAR2)
    IS
      SELECT paa.ass_attribute6   old_base_code
      FROM   per_all_people_f pap            -- 従業員マスタ
            ,per_all_assignments_f paa       -- アサインメントマスタ
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    ADD_MONTHS(TRUNC(gd_process_date, 'MM') ,-3) <= TO_DATE(paa.ass_attribute2 ,'YYYY/MM/DD')
      AND    pap.employee_number = iv_business_person
      ;
    -- 獲得営業員と拠点コードの紐付き権限用チェックカーソルレコード型
    check_db_person_rel_auth_rec  check_db_person_rel_auth_cur%ROWTYPE;
--
    -- 拠点コードと獲得営業員の紐付きチェックカーソル
    CURSOR check_db_code_relation_cur(
      iv_base_code       IN VARCHAR2
     ,iv_business_person IN VARCHAR2)
    IS
      SELECT pap.employee_number   new_employee_number
      FROM   per_all_people_f pap            -- 従業員マスタ
            ,per_all_assignments_f paa       -- アサインメントマスタ
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    paa.ass_attribute5  = iv_base_code
      AND    pap.employee_number = iv_business_person
      ;
    -- 拠点コードと獲得営業員の紐付きチェックレコード型
    check_db_code_relation_rec  check_db_code_relation_cur%ROWTYPE;
--
    -- 拠点コードと獲得営業員の紐付き権限用チェックカーソル
    CURSOR check_db_code_rel_auth_cur(
      iv_base_code       IN VARCHAR2
     ,iv_business_person IN VARCHAR2)
    IS
      SELECT pap.employee_number   old_employee_number
      FROM   per_all_people_f pap            -- 従業員マスタ
            ,per_all_assignments_f paa       -- アサインメントマスタ
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    ADD_MONTHS(TRUNC(gd_process_date, 'MM') ,-3) <= TO_DATE(paa.ass_attribute2 ,'YYYY/MM/DD')
      AND    paa.ass_attribute6  = iv_base_code
      AND    pap.employee_number = iv_business_person
      ;
    -- 拠点コードと獲得営業員の紐付き権限用チェックレコード型
    check_db_code_rel_auth_rec  check_db_code_rel_auth_cur%ROWTYPE;
--
    -- 新規ポイント区分チェックカーソル
    CURSOR check_new_point_div_cur(
      iv_new_point_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      new_point_div
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_new_point_div_type
      AND    flvv.lookup_code = iv_new_point_div
      ;
    -- 顧客ステータスチェックカーソルレコード型
    check_new_point_div_rec  check_new_point_div_cur%ROWTYPE;
--
    -- 紹介営業員存在チェックカーソル
    CURSOR check_db_intro_person_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.intro_business_person  intro_business_person
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- 紹介営業員存在チェックカーソルレコード型
    check_db_intro_person_rec  check_db_intro_person_cur%ROWTYPE;
--
    -- 従業員マスタチェックカーソル
    CURSOR check_db_mst_person_cur(
      iv_business_person IN VARCHAR2)
    IS
      SELECT pap.employee_number      employee_number
      FROM   per_all_people_f pap     -- 従業員マスタ
      WHERE  pap.employee_number = iv_business_person
      ;
    -- 従業員マスタチェックカーソルレコード型
    check_db_mst_person_rec  check_db_mst_person_cur%ROWTYPE;
--
    -- 紹介拠点存在チェックカーソル
    CURSOR check_db_intro_base_code_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.intro_base_code  intro_base_code
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- 紹介拠点存在チェックカーソルレコード型
    check_db_intro_base_code_rec  check_db_intro_base_code_cur%ROWTYPE;
--
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
    -- 参照タイプチェックカーソル
    CURSOR check_lookup_type_cur2(
      iv_lookup_code IN VARCHAR2
    , iv_lookup_type IN VARCHAR2
    )
    IS
      SELECT flvv.lookup_code  AS lookup_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type   = iv_lookup_type
      AND    flvv.lookup_code   = iv_lookup_code
      AND    flvv.enabled_flag  = cv_yes
      ;
    -- 参照タイプチェックカーソルレコード型
    check_lookup_type_rec2  check_lookup_type_cur2%ROWTYPE;
--
    -- 顧客追加情報現在値取得カーソル
    CURSOR get_xca_info_cur(
      iv_customer_code IN VARCHAR2
    )
    IS
      SELECT xca.ship_storage_code     AS ship_storage_code     --出荷元保管場所
            ,xca.tsukagatazaiko_div    AS tsukagatazaiko_div    --通過在庫型区分
            ,xca.chain_store_code      AS chain_store_code      --チェーン店コード(EDI)
            ,xca.delivery_base_code    AS delivery_base_code    --納品拠点
            ,xca.business_low_type     AS business_low_type     --業態（小分類）
            ,xca.selling_transfer_div  AS selling_transfer_div  --売上実績振替
            ,xca.longitude             AS longitude             --ピークカット開始時刻
            ,xca.rate                  AS rate                  --消化計算用掛率
            ,xca.conclusion_day1       AS conclusion_day1       --消化計算締め日1
            ,xca.conclusion_day2       AS conclusion_day2       --消化計算締め日2
            ,xca.conclusion_day3       AS conclusion_day3       --消化計算締め日3
-- Ver1.15 add start
            ,xca.invoice_printing_unit AS invoice_class         --請求書印刷単位
            ,xca.invoice_code          AS invoice_code          --請求書用コード
-- Ver1.15 add end
-- Ver1.16 add start
            ,xca.offset_cust_div       AS offset_cust_div       --相殺用顧客区分
            ,xca.offset_cust_code      AS offset_cust_code      --相殺用顧客コード
            ,xca.bp_customer_code      AS bp_customer_code      --取引先顧客コード
-- Ver1.16 add end
-- Ver1.19 add start
            ,xca.latitude              AS latitude              --カテゴリー商品計上区分
-- Ver1.19 add end
      FROM   hz_cust_accounts     hca
            ,xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code
      ;
    -- 顧客追加情報現在値取得カーソルレコード型
    get_xca_info_rec  get_xca_info_cur%ROWTYPE;
--
    -- 稼働日カレンダチェックカーソル
    CURSOR check_calendar_code_cur(
      iv_calendar_code IN VARCHAR2
    )
    IS
      SELECT bc.calendar_code   AS calendar_code
      FROM   bom_calendars  bc
      WHERE  bc.attribute1    = cv_yes
      AND    bc.calendar_code = iv_calendar_code
      ;
    -- 稼働日カレンダチェックカーソルレコード型
    check_calendar_code_rec  check_calendar_code_cur%ROWTYPE;
--
    -- 店舗営業用顧客コードチェックカーソル
    CURSOR check_store_cust_code_cur(
      iv_store_cust_code IN VARCHAR2
    )
    IS
      SELECT hca.account_number  AS store_cust_code
      FROM   hz_cust_accounts  hca
      WHERE  hca.customer_class_code  = cv_tenpo_kbn  --'15'(店舗営業)
      AND    hca.account_number       = iv_store_cust_code
      ;
    -- 店舗営業用顧客コードカーソルレコード型
    check_store_cust_code_rec  check_store_cust_code_cur%ROWTYPE;
--
    --出荷元保管場所相関チェックカーソル
    CURSOR check_ss_code_rel_cur(
      iv_ship_storage_code    IN VARCHAR2
     ,iv_chain_store_code     IN VARCHAR2
    )
    IS
      SELECT xca.edi_chain_code  AS chain_store_code
      FROM   xxcmm_cust_accounts xca
            ,hz_cust_accounts    hca
      WHERE  xca.customer_id         = hca.cust_account_id
        AND  hca.customer_class_code = cv_edi_class  --顧客区分'18'
        AND  xca.edi_chain_code      = iv_chain_store_code
        AND  EXISTS (SELECT 'X'
                     FROM  mtl_secondary_inventories msi
                          ,mtl_parameters            mp
                     WHERE msi.organization_id          = mp.organization_id
                       AND mp.organization_code         = gv_organization_code  --在庫組織
                       AND msi.attribute12              = xca.edi_chain_code
                       AND msi.attribute13              = cv_hokan_bunrui_3  --保管場所分類'3'
                       AND msi.secondary_inventory_name = iv_ship_storage_code
                    )
      ;
    --出荷元保管場所相関チェックカーソル型
    check_ss_code_rel_rec  check_ss_code_rel_cur%ROWTYPE;
-- Ver1.10 add end
-- Ver1.12 add start
    -- 顧客使用目的現在値取得カーソル
    CURSOR get_hcsu_info_cur(
      iv_customer_code IN VARCHAR2
    )
    IS
      SELECT hcsu.attribute7  AS invoice_form     --請求書出力形式
            ,hcsu.attribute8  AS invoice_cycle    --請求書発行サイクル
      FROM   hz_cust_accounts     hca
            ,hz_cust_acct_sites   hcas
            ,hz_cust_site_uses    hcsu
      WHERE  hca.cust_account_id    = hcas.cust_account_id
        AND  hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND  hcsu.site_use_code     = cv_bill_to
        AND  hcsu.status            = cv_a_flag
        AND  hca.account_number     = iv_customer_code
      ;
    -- 顧客使用目的現在値取得カーソルレコード型
    get_hcsu_info_rec  get_hcsu_info_cur%ROWTYPE;
-- Ver1.12 add end
-- Ver1.16 add start
    -- 相殺用顧客コードチェックカーソル
    CURSOR check_offset_cust_code_cur(
      iv_offset_cust_code IN VARCHAR2     -- 相殺用顧客コード
    )
    IS
      SELECT hca.account_number  AS offset_cust_code
        FROM xxcmm_cust_accounts xca
            ,hz_cust_accounts    hca
       WHERE xca.customer_id          = hca.cust_account_id
         AND hca.customer_class_code  = cv_kokyaku_kbn        -- 顧客区分：顧客
         AND xca.offset_cust_div      = cv_offset_cust_div_1  -- 相殺用顧客区分：相殺用顧客
         AND hca.account_number       = iv_offset_cust_code   -- 相殺用顧客区分
      ;
    -- 相殺用顧客コードカーソルレコード型
    check_offset_cust_code_rec  check_offset_cust_code_cur%ROWTYPE;
--
    -- 取引先顧客コード重複チェックカーソル
    CURSOR chk_bp_customer_code_cur(
      iv_offset_cust_code   IN VARCHAR2   -- 相殺用顧客コード
     ,iv_bp_customer_code   IN VARCHAR2   -- 取引先顧客コード
     ,iv_customer_code      IN VARCHAR2   -- 顧客コード
    )
    IS
      SELECT hca.account_number  AS bp_cust_exists
        FROM xxcmm_cust_accounts xca
            ,hz_cust_accounts    hca
       WHERE xca.customer_id         =  hca.cust_account_id
         AND xca.offset_cust_code    =  iv_offset_cust_code     -- 相殺用顧客コード
         AND xca.bp_customer_code    =  iv_bp_customer_code     -- 取引先顧客コード
         AND hca.account_number      <> iv_customer_code        -- 顧客コード
         AND ROWNUM                  =  1
      ;
    -- 取引先顧客コード重複チェックレコード型
    chk_bp_customer_code_rec chk_bp_customer_code_cur%ROWTYPE;
-- Ver1.16 add end
-- Ver1.19 add start
    -- カテゴリー商品計上区分不要業態小分類チェックカーソル
    CURSOR check_cat_prod_unn_cur(
      iv_lookup_code IN VARCHAR2     -- 業態小分類
    )
    IS
      SELECT COUNT(1)              AS cnt
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type      = cv_lkp_cat_prod_unn
      AND    flvv.lookup_code      = iv_lookup_code
      AND    flvv.enabled_flag     = cv_yes
      AND    NVL(flvv.start_date_active, gd_process_date) <= gd_process_date
      AND    NVL(flvv.end_date_active,   gd_process_date) >= gd_process_date
      ;
    -- カテゴリー商品計上区分不要業態小分類チェックカーソルレコード型
    check_cat_prod_unn_rec  check_cat_prod_unn_cur%ROWTYPE;
-- Ver1.19 add end
-- Ver1.25 add start
--
    -- 控除用チェーンコード取得カーソル
    CURSOR get_intro_chain_code2_cur(
      iv_customer_code      IN VARCHAR2   -- 顧客コード
    )
    IS
      SELECT xca.intro_chain_code2 AS intro_chain_code2
      FROM   xxcmm_cust_accounts xca
      WHERE  xca.customer_code = iv_customer_code
      ;
    -- 控除用チェーンコード取得カーソルレコード型
    get_intro_chain_code2_rec  get_intro_chain_code2_cur%ROWTYPE;
--
    --控除消込ヘッダー情報の消込ステータスチェックカーソル
    CURSOR check_dedu_chain_cur(
      iv_customer_code      IN VARCHAR2   -- 顧客コード
    )
    IS
      SELECT xdrh.recon_slip_num AS recon_slip_num
      FROM   xxcok_deduction_recon_head  xdrh  -- 控除消込ヘッダー情報
            ,xxcok_sales_deduction       xsd   -- 販売控除情報
            ,fnd_lookup_values_vl        flvv
      WHERE  xsd.customer_code_to    =   iv_customer_code
      AND    xdrh.recon_slip_num     =   xsd.recon_slip_num
      AND    xdrh.recon_status       IN  ('EG','SG','SD')
      AND    xdrh.interface_div      = 'WP'                                -- 問屋
      AND    xsd.data_type           = flvv.lookup_code                    -- 控除データ
      AND    flvv.lookup_type        = cv_lkp_dedu_data_type               -- 控除データ種類
      AND    flvv.attribute8         = cv_yes                              -- 立替フラグ：差額
      AND    flvv.enabled_flag       = cv_yes
      AND    NVL(flvv.start_date_active, gd_process_date) <= gd_process_date
      AND    NVL(flvv.end_date_active,   gd_process_date) >= gd_process_date
      GROUP BY xdrh.recon_slip_num
      ORDER BY xdrh.recon_slip_num
      ;
    --控除消込ヘッダー情報の消込ステータスチェックカーソルレコード型
    TYPE recon_slip_num_ttype IS TABLE OF check_dedu_chain_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_recon_slip_num_tab       recon_slip_num_ttype;
-- Ver1.25 add end
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 顧客一括更新用CSV情報取得
    << check_upload_file_loop >>
    FOR check_upload_file_rec IN check_upload_file_cur( in_file_id,
                                                        iv_format_pattern)
    LOOP
      lv_upload_file_name := check_upload_file_rec.file_name;
    END LOOP check_upload_file_loop;
    -- 顧客一括更新用CSV情報取得失敗時、エラー
    IF (lv_upload_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_csv_msg);
      lv_errbuf := lv_errmsg;
      RAISE get_csv_err_expt;
    END IF;
--
    --構造体初期化
    lr_cust_data_table.delete;
--
    --ファイルアップロードIFテーブルより、BLOBデータを変換した文字列構造体を取得する
    xxccp_common_pkg2.blob_to_varchar2(in_file_id,
                                       lr_cust_data_table,
                                       lv_errbuf,
                                       lv_retcode,
                                       lv_errmsg);
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_csv_msg);
      lv_errbuf := lv_errmsg;
      RAISE get_csv_err_expt;
    END IF;
--
    <<cust_data_wk_loop>>
    FOR ln_index IN lr_cust_data_table.first..lr_cust_data_table.last LOOP
      --エラーチェック変数初期化
      lv_check_status := cv_status_normal;
      --取得した文字列構造体をエラーチェック後、挿入
      lv_temp := lr_cust_data_table(ln_index);
--
      --初回のみヘッダチェック
      IF (ln_first_data = 1) THEN
        ln_first_data := 0;
        --顧客区分取得
        lv_customer_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,1);
        --取得した文字列構造体の１行１項目目が「顧客区分」以外の場合はエラーとする
        IF (lv_customer_class <> cv_cust_class) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_invalid_header_msg
                         );
          lv_errmsg := gv_out_msg;
          lv_errbuf := gv_out_msg;
          RAISE invalid_data_expt;
        END IF;
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
        -- ヘッダ項目数のチェック
        ln_item_num := LENGTH(lv_temp) - LENGTH(REPLACE(lv_temp, cv_comma, NULL)) + 1;
        -- 項目数が一致しない場合
        IF (gn_item_num <> ln_item_num) THEN
          -- エラーメッセージ表示
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_item_num_err_msg
                          ,iv_token_name1  => cv_table
                          ,iv_token_value1 => cv_xxcmm_003_a29c_name
                          ,iv_token_name2  => cv_count_token
                          ,iv_token_value2 => TO_CHAR(ln_item_num)
                         );
          lv_errmsg := gv_out_msg;
          lv_errbuf := gv_out_msg;
          RAISE invalid_data_expt;
        END IF;
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
      END IF;
--
      --ヘッダデータ読み飛ばし
      IF (lv_customer_class = cv_cust_class) THEN
        ln_first_data := 0;
      ELSE
        --顧客コード取得
        lv_customer_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.10 mod start
--                                                                   ,5);
                                                                   ,2);
-- Ver1.10 mod end
        --顧客コードの必須チェック
        IF   (lv_customer_code IS NULL)
          OR (lv_customer_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --顧客コード必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        IF (lv_customer_code IS NOT NULL) THEN
          --顧客コード存在チェック
          << check_cust_code_loop >>
          FOR check_cust_code_rec IN check_cust_code_cur( lv_customer_code )
          LOOP
            lv_cust_code_mst := check_cust_code_rec.cust_code;
            ln_cust_id       := check_cust_code_rec.cust_id;
            ln_party_id      := check_cust_code_rec.party_id;
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
            lv_cust_customer_class := check_cust_code_rec.cust_kbn;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
          END LOOP check_cust_code_loop;
          IF (lv_cust_code_mst IS NULL) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --顧客コードマスター存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_code
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_cust_acct_table
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
        END IF;
--
        --顧客追加情報存在チェック
        IF (ln_cust_id IS NOT NULL) THEN
          --顧客追加情報存在チェック
          << check_cust_addon_loop >>
          FOR check_cust_addon_rec IN check_cust_addon_cur( ln_cust_id )
          LOOP
            ln_cust_addon_mst := check_cust_addon_rec.customer_id;
          END LOOP check_cust_addon_loop;
        END IF;
        IF (ln_cust_addon_mst IS NULL) THEN
          --顧客追加情報エラー
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --顧客コードマスター存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_cust_addon_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
        END IF;
--
        --顧客区分取得
        lv_customer_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,1);
-- 2017/10/18 Ver1.17 E_本稼動_14667 add start by Y.Omuro
        --現行顧客ステータス取得
        << get_cust_status_loop >>
        FOR get_cust_status_rec IN get_cust_status_cur( ln_party_id )
        LOOP
          lv_get_cust_status := get_cust_status_rec.cust_status;
        END LOOP get_cust_status_loop;
--
        IF    (lv_customer_class IS NULL
          AND  (lv_get_cust_status = cv_mc_candidates
            OR  lv_get_cust_status = cv_mc)) THEN
          -- 顧客区分がNULL、かつ顧客ステータスが10(MC候補)または20(MC)はチェックしない
          NULL;
        ELSE
-- 2017/10/18 Ver1.17 E_本稼動_14667 add end by Y.Omuro
          --顧客区分存在チェック
          << check_cust_class_loop >>
          FOR check_cust_class_rec IN check_cust_class_cur( lv_customer_class )
          LOOP
            lv_cust_class_mst := check_cust_class_rec.cust_class;
          END LOOP check_cust_class_loop;
          IF (lv_cust_class_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --顧客区分参照表存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_class
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --顧客区分の型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_cust_class      --項目名称
                                              ,lv_customer_class  --顧客区分
                                              ,2                  --項目長
                                              ,NULL               --項目長（小数点以下）
                                              ,cv_null_ok         --必須フラグ
                                              ,cv_element_vc2     --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf     --エラーバッファ
                                              ,lv_item_retcode    --エラーコード
                                              ,lv_item_errmsg);   --エラーメッセージ
          --顧客区分が存在し、かつ型・桁数チェックエラー時
          IF (lv_customer_class IS NOT NULL)
            AND (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
--不具合ID007 2007/02/24 add start
            lv_retcode      := cv_status_error;
--add end
            --顧客区分エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_class
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg);
          END IF;
-- 2017/10/18 Ver1.17 E_本稼動_14667 add start by Y.Omuro
        END IF;
-- 2017/10/18 Ver1.17 E_本稼動_14667 add end by Y.Omuro
--
        --顧客名称取得
        lv_customer_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.10 mod start
--                                                                   ,6);
                                                                   ,3);
-- Ver1.10 mod end
        --顧客名称の必須チェック
        IF (lv_customer_name = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --顧客名称必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        IF (lv_customer_name IS NOT NULL) THEN
          --顧客名称の型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_cust_name      --項目名称
                                              ,lv_customer_name  --顧客名称
                                              ,100               --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --顧客名称が存在し、かつ型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --顧客名称エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_name
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_name
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg);
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          --全角文字チェック
          IF (xxccp_common_pkg.chk_double_byte(lv_customer_name) = FALSE) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --全角文字チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_name
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_name
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --顧客名称カナ取得
        lv_cust_name_kana := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,7);
                                                                     ,4);
-- Ver1.10 mod end
        --顧客名称カナの型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_cust_name_kana  --項目名称カナ
                                            ,lv_cust_name_kana  --顧客名称カナ
                                            ,50                 --項目長
                                            ,NULL               --項目長（小数点以下）
                                            ,cv_null_ok         --必須フラグ
                                            ,cv_element_vc2     --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf     --エラーバッファ
                                            ,lv_item_retcode    --エラーコード
                                            ,lv_item_errmsg);   --エラーメッセージ
        --顧客名称カナが存在し、かつ型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --顧客名称カナエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
-- 2009/03/25 Ver1.1 modify start by Yutaka.Kuboshima
--        --顧客名称カナの全角カタカナチェック
--        IF    (lv_cust_name_kana <> cv_null_bar)
--          AND (xxccp_common_pkg.chk_double_byte_kana( lv_cust_name_kana ) = FALSE) THEN
--          lv_check_status := cv_status_error;
--          lv_retcode      := cv_status_error;
--          --全角カタカナチェックエラーメッセージ取得
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => gv_xxcmm_msg_kbn
--                          ,iv_name         => cv_double_byte_kana_msg
--                          ,iv_token_name1  => cv_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_col_name
--                          ,iv_token_value2 => cv_cust_name_kana
--                          ,iv_token_name3  => cv_input_val
--                          ,iv_token_value3 => lv_cust_name_kana
--                         );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--        END IF;
        --顧客名称カナの半角文字チェック
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_cust_name_kana), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --半角文字チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
-- 2009/03/25 Ver1.1 modify end by Yutaka.Kuboshima
--
        --略称取得
        lv_cust_name_ryaku := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,8);
                                                                     ,5);
-- Ver1.10 mod end
--
        --略称の型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_ryaku            --項目名称カナ
                                            ,lv_cust_name_ryaku  --顧客名称カナ
-- 2010/01/27 Ver1.4 E_本稼動_01279 modify start by Yutaka.Kuboshima
--                                            ,50                  --項目長
                                            ,80                  --項目長
-- 2010/01/27 Ver1.4 E_本稼動_01279 modify end by Yutaka.Kuboshima
                                            ,NULL                --項目長（小数点以下）
                                            ,cv_null_ok          --必須フラグ
                                            ,cv_element_vc2      --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf      --エラーバッファ
                                            ,lv_item_retcode     --エラーコード
                                            ,lv_item_errmsg);    --エラーメッセージ
        --略称型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --略称エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_ryaku
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_ryaku
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
--
        --業態（小分類）取得
        lv_business_low_type := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                       ,30);
-- Ver1.10 mod start
--                                                                       ,32);
                                                                       ,25);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--        --業態（小分類）の必須チェック
--        IF (lv_business_low_type = cv_null_bar) THEN
--          lv_check_status := cv_status_error;
--          lv_retcode      := cv_status_error;
--          --業態（小分類）必須エラーメッセージ取得
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => gv_xxcmm_msg_kbn
--                          ,iv_name         => cv_required_err_msg
--                          ,iv_token_name1  => cv_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_col_name
--                          ,iv_token_value2 => cv_bus_low_type
--                         );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--        END IF;
--        --業態（小分類）が-でない場合
--        IF (lv_business_low_type <> cv_null_bar) THEN
--          --業態（小分類）存在チェック
--          << check_business_low_type_loop >>
--          FOR check_business_low_rec IN check_business_low_cur( lv_business_low_type )
--          LOOP
--            lv_business_low_mst := check_business_low_rec.business_low_type;
--          END LOOP check_business_low_type_loop;
--          IF (lv_business_low_mst IS NULL) THEN
--            lv_check_status   := cv_status_error;
--            lv_retcode        := cv_status_error;
--            --業態（小分類）参照表存在チェックエラーメッセージ取得
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_lookup_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_bus_low_type
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_business_low_type
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg);
--          END IF;
--          --業態（小分類）チェック
--          xxccp_common_pkg2.upload_item_check( cv_bus_low_type       --業態（小分類）
--                                              ,lv_business_low_type  --業態（小分類）
--                                              ,2                     --項目長
--                                              ,NULL                  --項目長（小数点以下）
--                                              ,cv_null_ok            --必須フラグ
--                                              ,cv_element_vc2        --属性（0・検証なし、1、数値、2、日付）
--                                              ,lv_item_errbuf        --エラーバッファ
--                                              ,lv_item_retcode       --エラーコード
--                                              ,lv_item_errmsg);      --エラーメッセージ
--          --業態（小分類）型・桁数チェックエラー時
--          IF (lv_item_retcode <> cv_status_normal) THEN
--            lv_check_status := cv_status_error;
--            lv_retcode      := cv_status_error;
--            --業態（小分類）エラーメッセージ取得
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_val_form_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_bus_low_type
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_business_low_type
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => lv_item_errmsg
--            );
--          END IF;
--        END IF;
        --業態（小分類）チェック
        xxccp_common_pkg2.upload_item_check( cv_bus_low_type       --業態（小分類）
                                            ,lv_business_low_type  --業態（小分類）
                                            ,2                     --項目長
                                            ,NULL                  --項目長（小数点以下）
                                            ,cv_null_ok            --必須フラグ
                                            ,cv_element_vc2        --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf        --エラーバッファ
                                            ,lv_item_retcode       --エラーコード
                                            ,lv_item_errmsg);      --エラーメッセージ
        --業態（小分類）型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --業態（小分類）エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_bus_low_type
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_business_low_type
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
-- Ver1.10 add start
          --業態(小分類)チェックフラグFALSE
          lb_bz_low_type_chk_flg := FALSE;
-- Ver1.10 add end
        END IF;
        -- 顧客区分'10','12','13','14','15','16','17'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          --業態（小分類）の相関チェック
          -- 顧客区分'10'(顧客)、'12'(上様顧客)、'15'(店舗営業)の場合、入力必須
          IF    (lv_business_low_type = cv_null_bar)
            AND (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn, cv_tenpo_kbn ) )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --業態（小分類）相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_bus_low_type
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.10 add start
            --業態(小分類)チェックフラグFALSE
            lb_bz_low_type_chk_flg := FALSE;
-- Ver1.10 add end
          END IF;
          --業態（小分類）が-でない場合
          IF (lv_business_low_type <> cv_null_bar) THEN
            --業態（小分類）存在チェック
            << check_business_low_type_loop >>
            FOR check_business_low_rec IN check_business_low_cur( lv_business_low_type )
            LOOP
              lv_business_low_mst := check_business_low_rec.business_low_type;
            END LOOP check_business_low_type_loop;
            IF (lv_business_low_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --業態（小分類）参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_bus_low_type
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_business_low_type
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
-- Ver1.10 add start
              --業態(小分類)チェックフラグFALSE
              lb_bz_low_type_chk_flg := FALSE;
-- Ver1.10 add end
            END IF;
          END IF;
-- Ver1.10 add start
          --業態(小分類)の妥当性チェックOKの場合
          IF (lb_bz_low_type_chk_flg = TRUE)
          THEN
            -- チェック用に顧客追加情報の現在値を取得
            << get_xca_info_loop >>
            FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
            LOOP
              lt_business_low_type_bef  := get_xca_info_rec.business_low_type;
            END LOOP get_xca_info_loop;
            --
            --職責管理フラグが'N'かつ、変更前の値が'21'、'22'、'27'、'24'、'25'の場合は更新不可
            IF    (gv_resp_flag = cv_no)
              AND (NVL(lv_business_low_type ,cv_null_bar) <> cv_null_bar)
              AND (lv_business_low_type <> lt_business_low_type_bef)
              AND (lt_business_low_type_bef IN ( cv_gyotai_inshop
                                               , cv_gyotai_tosya_tyokuei
                                               , cv_gyotai_syoka_vd
                                               , cv_gyotai_full_syoka_vd
                                               , cv_gyotai_full_vd ))
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --現在値更新可否チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_now_update_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_bus_low_type
                              ,iv_token_name2  => cv_input_val
                              ,iv_token_value2 => lt_business_low_type_bef
                              ,iv_token_name3  => cv_cust_code
                              ,iv_token_value3 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
                --業態(小分類)チェックフラグFALSE
                lb_bz_low_type_chk_flg := FALSE;
            END IF;
          END IF;
-- Ver1.10 add end
        END IF;
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
-- Ver1.10 add start
        --業態(小分類)の妥当性チェックOKの場合、更新値を取得
        IF (lb_bz_low_type_chk_flg = TRUE)
        THEN
          --変更値が'-'の場合
          IF (lv_business_low_type = cv_null_bar)
          THEN
            lt_business_low_type_aft := NULL;
          --変更値がNULLまたは、
          --顧客区分が'18','19','20','21'の場合
          ELSIF (lv_business_low_type IS NULL)
            OR  (lv_cust_customer_class IN ( cv_edi_class
                                           , cv_hyakkaten_kbn
                                           , cv_seikyusho_kbn
                                           , cv_toukatu_kbn))
          THEN
            --更新前の値を設定
            lt_business_low_type_aft := lt_business_low_type_bef;
          ELSE
            --CSVの値を設定
            lt_business_low_type_aft := lv_business_low_type;
          END IF;
--
-- Ver1.11 del start
--          --職責管理フラグが'N'の場合
--          IF (gv_resp_flag = cv_no)
--          THEN
--            --顧客区分：12かつ、変更後の値が'21','22','27'の場合
--            IF     (lv_cust_customer_class = cv_uesama_kbn)
--              AND  (lt_business_low_type_aft IN ( cv_gyotai_inshop
--                                                , cv_gyotai_tosya_tyokuei
--                                                , cv_gyotai_syoka_vd ))
--            THEN
--              lv_check_status := cv_status_error;
--              lv_retcode      := cv_status_error;
--              --業態(小分類)妥当性チェックエラーメッセージ取得
--              gv_out_msg := xxccp_common_pkg.get_msg(
--                               iv_application  => gv_xxcmm_msg_kbn
--                              ,iv_name         => cv_bz_low_type_err_msg
--                              ,iv_token_name1  => cv_input_val
--                              ,iv_token_value1 => lv_cust_customer_class
--                              ,iv_token_name2  => cv_cond_col_val
--                              ,iv_token_value2 => lt_business_low_type_aft
--                              ,iv_token_name3  => cv_cust_code
--                              ,iv_token_value3 => lv_customer_code
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => gv_out_msg);
--                --業態(小分類)チェックフラグFALSE
--                lb_bz_low_type_chk_flg := FALSE;
----
--            --顧客区分：10以外かつ、変更後の値が'21','22','24','25','26','27'の場合
--            ELSIF  (lv_cust_customer_class <> cv_kokyaku_kbn)
--              AND  (lt_business_low_type_aft IN ( cv_gyotai_inshop
--                                                , cv_gyotai_tosya_tyokuei
--                                                , cv_gyotai_full_syoka_vd
--                                                , cv_gyotai_full_vd
--                                                , cv_gyotai_nohin_vd
--                                                , cv_gyotai_syoka_vd ))
--            THEN
--              lv_check_status := cv_status_error;
--              lv_retcode      := cv_status_error;
--              --業態(小分類)妥当性チェックエラーメッセージ取得
--              gv_out_msg := xxccp_common_pkg.get_msg(
--                               iv_application  => gv_xxcmm_msg_kbn
--                              ,iv_name         => cv_bz_low_type_err_msg
--                              ,iv_token_name1  => cv_input_val
--                              ,iv_token_value1 => lv_cust_customer_class
--                              ,iv_token_name2  => cv_cond_col_val
--                              ,iv_token_value2 => lt_business_low_type_aft
--                              ,iv_token_name3  => cv_cust_code
--                              ,iv_token_value3 => lv_customer_code
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => gv_out_msg);
--                --業態(小分類)チェックフラグFALSE
--                lb_bz_low_type_chk_flg := FALSE;
--            END IF;
--          END IF;
-- Ver1.11 del end
        END IF;
-- Ver1.10 add end
--
        --顧客ステータス取得
        lv_customer_status := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,9);
                                                                     ,24);
-- Ver1.10 mod end
        --顧客ステータスの必須チェック
        IF (lv_customer_status = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --顧客ステータス必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_status
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
        END IF;
        --顧客ステータスが-でない場合
        IF (lv_customer_status <> cv_null_bar) THEN
          --顧客ステータス存在チェック
          << check_cust_status_loop >>
          FOR check_cust_status_rec IN check_cust_status_cur( lv_customer_status )
          LOOP
            lv_cust_status_mst := check_cust_status_rec.cust_status;
          END LOOP check_cust_status_loop;
          IF (lv_cust_status_mst IS NULL) THEN
            lv_check_status    := cv_status_error;
            lv_retcode         := cv_status_error;
            --顧客ステータス参照表存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_status
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_status
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
          --顧客ステータスが参照表に存在する場合、変更チェック
          IF (lv_cust_status_mst IS NOT NULL) THEN
            --現行顧客ステータス取得
            << get_cust_status_loop >>
            FOR get_cust_status_rec IN get_cust_status_cur( ln_party_id )
            LOOP
              lv_get_cust_status := get_cust_status_rec.cust_status;
            END LOOP get_cust_status_loop;
            --ステータスが変更可能かチェック
            IF (xxcmm_003common_pkg.cust_status_update_allow( lv_customer_class
                                                             ,lv_get_cust_status
                                                             ,lv_customer_status) <> cv_status_normal) THEN
                lv_check_status  := cv_status_error;
                lv_retcode       := cv_status_error;
                --変更不能エラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_status_func_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_pre_status
                                ,iv_token_value2 => lv_get_cust_status
                                ,iv_token_name3  => cv_will_status
                                ,iv_token_value3 => lv_customer_status
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
            END IF;
            IF (lv_customer_status = cv_stop_approved) THEN
-- 2010/02/15 Ver1.5 E_本稼動01582 add start by Yutaka.Kuboshima
-- Ver1.10 del start
--              -- 現在設定されている業態(小分類)を取得
--              << get_business_low_type_loop >>
--              FOR get_business_low_type_rec IN get_business_low_type_cur( ln_cust_id )
--              LOOP
--                lv_business_low_type_now := get_business_low_type_rec.business_low_type;
--              END LOOP get_business_low_type_loop;
--              -- 新しく設定する業態(小分類)がNOT NULL かつ、'-'以外かつ、現在設定されている業態(小分類)と違う場合
--              IF (lv_business_low_type IS NOT NULL)
--                AND (lv_business_low_type <> cv_null_bar)
--                AND (lv_business_low_type_now <> lv_business_low_type)
--              THEN
--                lv_business_low_type_now := lv_business_low_type;
--              END IF;
-- Ver1.10 del end
-- 2010/02/15 Ver1.5 E_本稼動01582 add end by Yutaka.Kuboshima
              --顧客ステータス変更チェック
              xxcmm_cust_sts_chg_chk_pkg.main( ln_cust_id
-- 2010/02/15 Ver1.5 E_本稼動01582 modify start by Yutaka.Kuboshima
--                                              ,lv_customer_status
-- Ver1.10 mod start
--                                              ,lv_business_low_type_now
                                              ,lt_business_low_type_bef
-- Ver1.10 mod end
-- 2010/02/15 Ver1.5 E_本稼動01582 modify end by Yutaka.Kuboshima
                                              ,lv_item_retcode
                                              ,lv_item_errmsg);
              IF (lv_item_retcode = cv_modify_err) THEN
--不具合ID007 2007/02/24 modify start
--                lv_cust_status_mst := cv_status_error;
                lv_check_status  := cv_status_error;
--modify end
                lv_retcode       := cv_status_error;
                --顧客ステータス変更チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_status_modify_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_input_val
                                ,iv_token_value2 => lv_customer_status
                                ,iv_token_name3  => cv_ret_code
                                ,iv_token_value3 => lv_item_retcode
                                ,iv_token_name4  => cv_ret_msg
                                ,iv_token_value4 => lv_item_errmsg
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
        END IF;
--
        --中止理由取得
        lv_approval_reason := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,10);
                                                                     ,32);
-- Ver1.10 mod end
        --中止理由が-でない場合
        IF (lv_approval_reason <> cv_null_bar) THEN
          --中止理由存在チェック
          << check_approval_reason_loop >>
          FOR check_approval_reason_rec IN check_approval_reason_cur( lv_approval_reason )
          LOOP
            lv_appr_reason_mst := check_approval_reason_rec.approval_reason;
          END LOOP check_approval_reason_loop;
          IF (lv_appr_reason_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --中止理由参照表存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_reason
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_reason
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --中止理由型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_appr_reason        --中止理由
                                              ,lv_approval_reason    --中止理由
                                              ,1                     --項目長
                                              ,NULL                  --項目長（小数点以下）
                                              ,cv_null_ok            --必須フラグ
                                              ,cv_element_vc2        --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf        --エラーバッファ
                                              ,lv_item_retcode       --エラーコード
                                              ,lv_item_errmsg);      --エラーメッセージ
          --中止理由型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --中止理由エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_reason
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_reason
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --中止決済日取得
        lv_approval_date := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.10 mod start
--                                                                   ,11);
                                                                   ,31);
-- Ver1.10 mod end
        --中止決済日がNULLでない場合
        IF (lv_approval_date <> cv_null_bar) THEN
          --中止決済日型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_appr_date      --中止決済日
                                              ,lv_approval_date  --中止決済日
                                              ,NULL              --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_dat    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --中止決済日型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --中止決済日エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_date
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_date
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
          --顧客ステータスを'90'(中止決裁済)に変更する初回のみ
          --未来日チェック、会計期間チェックを実施
          IF (lv_customer_status = cv_stop_approved)
            AND (lv_get_cust_status <> lv_customer_status)
            AND (lv_item_retcode = cv_status_normal)
          THEN
            --未来日チェック
            --業務日付より未来日の場合はエラー
            IF (TO_DATE(lv_approval_date, cv_date_format) > gd_process_date) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --中止決済日未来日メッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_stop_date_future_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_input_val
                              ,iv_token_value2 => lv_approval_date
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --会計期間クローズステータス取得
              << get_period_status_loop >>
              FOR get_period_status_rec IN get_period_status_cur(TO_DATE(lv_approval_date, cv_date_format))
              LOOP
                lv_period_status := get_period_status_rec.period_status;
              END LOOP get_period_status_loop;
              --
              --会計期間がクローズしている日付を指定している場合
              IF (lv_period_status = cv_close_status) THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --中止決済日妥当性メッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_stop_date_val_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_input_val
                                ,iv_token_value2 => lv_approval_date
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_item_errmsg
                );
              END IF;
            END IF;
          END IF;
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
        END IF;
--
        --売掛コード１（請求書）取得
        lv_ar_invoice_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,14);
                                                                     ,19);
-- Ver1.10 mod end
        --売掛コード１（請求書）が-でない場合
        IF (lv_ar_invoice_code <> cv_null_bar) THEN
          --売掛コード１（請求書）存在チェック
          << check_ar_invoice_code_loop >>
          FOR check_ar_invoice_code_rec IN check_ar_invoice_code_cur( lv_ar_invoice_code )
          LOOP
            lv_ar_invoice_code_mst := check_ar_invoice_code_rec.ar_invoice_code;
          END LOOP check_ar_invoice_code_loop;
          IF (lv_ar_invoice_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --売掛コード１（請求書）存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_invoice
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_invoice_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --売掛コード１（請求書）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_ar_invoice       --売掛コード１（請求書）
                                              ,lv_ar_invoice_code  --売掛コード１（請求書）
                                              ,12                  --項目長
                                              ,NULL                --項目長（小数点以下）
                                              ,cv_null_ok          --必須フラグ
                                              ,cv_element_vc2      --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf      --エラーバッファ
                                              ,lv_item_retcode     --エラーコード
                                              ,lv_item_errmsg);    --エラーメッセージ
          --売掛コード１（請求書）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --売掛コード１（請求書）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_invoice
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_invoice_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --売掛コード２（事業所）取得
        lv_ar_location_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- Ver1.10 mod start
--                                                                      ,15);
                                                                      ,20);
-- Ver1.10 mod end
        --売掛コード２（事業所）が-でない場合
        IF (lv_ar_location_code <> cv_null_bar) THEN
          --売掛コード２（事業所）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_ar_location_code  --売掛コード２（事業所）
                                              ,lv_ar_location_code  --売掛コード２（事業所）
                                              ,12                   --項目長
                                              ,NULL                 --項目長（小数点以下）
                                              ,cv_null_ok           --必須フラグ
                                              ,cv_element_vc2       --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf       --エラーバッファ
                                              ,lv_item_retcode      --エラーコード
                                              ,lv_item_errmsg);     --エラーメッセージ
          --売掛コード２（事業所）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --売掛コード２（事業所）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_location_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_location_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --売掛コード３（その他）取得
        lv_ar_others_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- Ver1.10 mod start
--                                                                    ,16);
                                                                    ,21);
-- Ver1.10 mod end
        --売掛コード３（その他）が-でない場合
        IF (lv_ar_others_code <> cv_null_bar) THEN
          --売掛コード３（その他）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_ar_others_code  --売掛コード３（その他）
                                              ,lv_ar_others_code  --売掛コード３（その他）
                                              ,12                 --項目長
                                              ,NULL               --項目長（小数点以下）
                                              ,cv_null_ok         --必須フラグ
                                              ,cv_element_vc2     --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf     --エラーバッファ
                                              ,lv_item_retcode    --エラーコード
                                              ,lv_item_errmsg);   --エラーメッセージ
          --売掛コード３（その他）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --売掛コード３（その他）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_others_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_others_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --請求書発行区分取得
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
-- ※請求書発行区分 -> 請求書印刷単位に変更
--
--        lv_invoice_class := xxccp_common_pkg.char_delim_partition(  lv_temp
--                                                                   ,cv_comma
--                                                                   ,17);
--        --請求書発行区分の必須チェック
--        IF (lv_invoice_class = cv_null_bar) THEN
--          lv_check_status := cv_status_error;
--          lv_retcode      := cv_status_error;
--          --請求書発行区分必須エラーメッセージ取得
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => gv_xxcmm_msg_kbn
--                          ,iv_name         => cv_required_err_msg
--                          ,iv_token_name1  => cv_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_col_name
--                          ,iv_token_value2 => cv_invoice_kbn
--                         );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--        END IF;
--        IF (lv_invoice_class <> cv_null_bar) THEN
--          --請求書発行区分存在チェック
--          << check_invoice_class_loop >>
--          FOR check_invoice_class_rec IN check_invoice_class_cur( lv_invoice_class )
--          LOOP
--            lv_invoice_class_mst := check_invoice_class_rec.invoice_class;
--          END LOOP check_invoice_class_loop;
--          IF (lv_invoice_class_mst IS NULL) THEN
--            lv_check_status   := cv_status_error;
--            lv_retcode        := cv_status_error;
--            --請求書発行区分存在チェックエラーメッセージ取得
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_lookup_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_invoice_kbn
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_invoice_class
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg);
--          END IF;
--          --請求書発行区分型・桁数チェック
--          xxccp_common_pkg2.upload_item_check( cv_invoice_kbn    --請求書発行区分
--                                              ,lv_invoice_class  --請求書発行区分
--                                              ,1                 --項目長
--                                              ,NULL              --項目長（小数点以下）
--                                              ,cv_null_ok        --必須フラグ
--                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
--                                              ,lv_item_errbuf    --エラーバッファ
--                                              ,lv_item_retcode   --エラーコード
--                                              ,lv_item_errmsg);  --エラーメッセージ
--          --請求書発行区分型・桁数チェックエラー時
--          IF (lv_item_retcode <> cv_status_normal) THEN
--            lv_check_status := cv_status_error;
--            lv_retcode      := cv_status_error;
--            --請求書発行区分エラーメッセージ取得
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_val_form_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_invoice_kbn
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_invoice_class
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => lv_item_errmsg
--            );
--          END IF;
--        END IF;
--
        lv_invoice_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.10 mod start
--                                                                   ,17);
                                                                   ,51);
-- Ver1.10 mod end
        --請求書印刷単位型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_invoice_kbn    --請求書印刷単位
                                            ,lv_invoice_class  --請求書印刷単位
                                            ,1                 --項目長
                                            ,NULL              --項目長（小数点以下）
                                            ,cv_null_ok        --必須フラグ
                                            ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf    --エラーバッファ
                                            ,lv_item_retcode   --エラーコード
                                            ,lv_item_errmsg);  --エラーメッセージ
        --請求書印刷単位型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --請求書印刷単位エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_invoice_kbn
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_invoice_class
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
-- Ver1.15 add start
          lb_invoice_chk_flg := FALSE;
-- Ver1.15 add end
        END IF;
        -- 顧客区分'10'の場合のみエラーチェックを行う
        IF (lv_cust_customer_class = cv_kokyaku_kbn) THEN
          --請求書印刷単位の相関チェック
          IF (lv_invoice_class = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書印刷単位相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_invoice_kbn
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.15 add start
            lb_invoice_chk_flg := FALSE;
-- Ver1.15 add end
          END IF;
-- Ver1.15 add start
          IF ( lb_invoice_chk_flg = TRUE ) THEN
            --顧客追加情報の現在値を取得
            << get_xca_info_loop >>
            FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
            LOOP
              lt_invoice_class_bef := get_xca_info_rec.invoice_class;
            END LOOP get_xca_info_loop;
--
            --請求書印刷単位の更新値を取得
            IF ( lv_invoice_class = cv_null_bar )
            THEN
              lt_invoice_class_aft := NULL;
            ELSIF ( lv_invoice_class IS NULL )
            THEN
              lt_invoice_class_aft := lt_invoice_class_bef;
            ELSE
              lt_invoice_class_aft := lv_invoice_class;
            END IF;
          END IF;
-- Ver1.15 add end
-- Ver1.15 mod start
--          IF (lv_invoice_class <> cv_null_bar) THEN
          IF ( lt_invoice_class_aft IS NOT NULL ) THEN
-- Ver1.15 mod end
            --請求書印刷単位存在チェック
            << check_invoice_class_loop >>
-- Ver1.15 mod start
--            FOR check_invoice_class_rec IN check_invoice_class_cur( lv_invoice_class )
            FOR check_invoice_class_rec IN check_invoice_class_cur( lt_invoice_class_aft )
-- Ver1.15 mod end
            LOOP
              lv_invoice_class_mst     := check_invoice_class_rec.invoice_class;
              lv_invoice_required_flag := check_invoice_class_rec.required_flag;
-- Ver1.15 add start
              lv_invoice_trust_flag    := check_invoice_class_rec.trust_flag;
-- Ver1.15 add end
            END LOOP check_invoice_class_loop;
            IF (lv_invoice_class_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --請求書印刷単位存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_invoice_kbn
                              ,iv_token_name3  => cv_input_val
-- Ver1.15 mod start
--                              ,iv_token_value3 => lv_invoice_class
                              ,iv_token_value3 => lt_invoice_class_aft
-- Ver1.15 mod end
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
-- Ver1.15 add start
              lb_invoice_chk_flg := FALSE;
-- Ver1.15 add end
            END IF;
          END IF;
        END IF;
-- 2009/10/23 Ver1.2 modify end by Yutaka.Kuboshima
--
        --請求書発行サイクル取得
        lv_invoice_cycle := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.10 mod start
--                                                                   ,18);
                                                                   ,23);
-- Ver1.10 mod end
--
        --請求書発行サイクルが-でない場合
        IF (lv_invoice_cycle <> cv_null_bar) THEN
          --請求書発行サイクル存在チェック
          << check_invoice_cycle_loop >>
          FOR check_invoice_cycle_rec IN check_invoice_cycle_cur( lv_invoice_cycle )
          LOOP
            lv_invoice_cycle_mst := check_invoice_cycle_rec.invoice_cycle;
          END LOOP check_invoice_cycle_loop;
          IF (lv_invoice_cycle_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --請求書発行サイクル存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_cycle
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_cycle
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.12 add start
            lb_invoice_chk_flg := FALSE;
-- Ver1.12 add end
          END IF;
          --請求書発行サイクル型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_invoice_cycle  --請求書発行サイクル
                                              ,lv_invoice_cycle  --請求書発行サイクル
                                              ,1                 --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --請求書発行サイクル型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書発行サイクルエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_cycle
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_cycle
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
-- Ver1.12 add start
            lb_invoice_chk_flg := FALSE;
-- Ver1.12 add end
          END IF;
        END IF;
--
        --請求書出力形式取得
        lv_invoice_form  := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.10 mod start
--                                                                   ,19);
                                                                   ,22);
-- Ver1.10 mod end
        --請求書出力形式が-でない場合
        IF (lv_invoice_form <> cv_null_bar) THEN
          --請求書出力形式存在チェック
          << check_invoice_form_loop >>
          FOR check_invoice_form_rec IN check_invoice_form_cur( lv_invoice_form )
          LOOP
            lv_invoice_form_mst := check_invoice_form_rec.invoice_form;
          END LOOP check_invoice_form_loop;
          IF (lv_invoice_form_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --請求書出力形式存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_ksk
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_form
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.12 add start
            lb_invoice_chk_flg := FALSE;
-- Ver1.12 add end
          END IF;
          --請求書出力形式型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_invoice_ksk    --請求書出力形式
                                              ,lv_invoice_form   --請求書出力形式
                                              ,1                 --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --請求書出力形式型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書出力形式エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_ksk
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_form
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
-- Ver1.12 add start
            lb_invoice_chk_flg := FALSE;
-- Ver1.12 add end
          END IF;
        END IF;
--
-- Ver1.12 add start
        --請求書関連の妥当性チェックOKかつ、
        --顧客区分が'10','12','14'の場合、現在値を取得
        IF (lb_invoice_chk_flg = TRUE)
          AND (lv_cust_customer_class IN ( cv_kokyaku_kbn
                                         , cv_uesama_kbn
                                         , cv_urikake_kbn ) )
        THEN
          --顧客使用目的の現在値を取得
          << get_hcsu_info_loop >>
          FOR get_hcsu_info_rec IN get_hcsu_info_cur( lv_customer_code )
          LOOP
            lt_invoice_form_bef   := get_hcsu_info_rec.invoice_form;
            lt_invoice_cycle_bef  := get_hcsu_info_rec.invoice_cycle;
          END LOOP get_hcsu_info_loop;
--
          --請求書出力形式の更新値を取得
          IF (lv_invoice_form = cv_null_bar)
          THEN
            lt_invoice_form_aft := NULL;
          ELSIF (lv_invoice_form IS NULL)
          THEN
            lt_invoice_form_aft := lt_invoice_form_bef;
          ELSE
            lt_invoice_form_aft := lv_invoice_form;
          END IF;
--
          ---請求書発行サイクルの更新値を取得
          IF (lv_invoice_cycle = cv_null_bar)
          THEN
            lt_invoice_cycle_aft := NULL;
          ELSIF (lv_invoice_cycle IS NULL)
          THEN
            lt_invoice_cycle_aft := lt_invoice_cycle_bef;
          ELSE
            lt_invoice_cycle_aft := lv_invoice_cycle;
          END IF;
--
          --請求書発行サイクルチェック
          --請求書出力形式が'4'かつ請求書発行サイクルが'1'以外の場合エラー
          IF (lt_invoice_form_aft = cv_invoice_form_4)
            AND (NVL(lt_invoice_cycle_aft ,cv_dummy_0) <> cv_invoice_cycle_1)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書発行サイクルチェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_invoice_cycle_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
--
        END IF;
-- Ver1.12 add end
-- Ver1.15 add start
        --請求書印刷単位チェック
        --請求書関連の妥当性チェックOK、かつ顧客区分が'10'の場合
        IF ( lb_invoice_chk_flg = TRUE )
          AND ( lv_cust_customer_class = cv_kokyaku_kbn )
        THEN
          --請求書出力形式が'4'かつ業者委託時設定可否フラグが'N'の場合エラー
          IF ( lt_invoice_form_aft = cv_invoice_form_4 )
            AND ( lv_invoice_trust_flag = cv_no )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書印刷単位チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_inv_prt_unit_err_msg
                            ,iv_token_name1  => cv_value
                            ,iv_token_value1 => lt_invoice_class_aft
                            ,iv_token_name2  => cv_cust_code
                            ,iv_token_value2 => lv_customer_code
                          );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
        END IF;
-- Ver1.15 add end
        --支払条件取得
        lv_payment_term_id := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,20);
                                                                     ,15);
-- Ver1.10 mod end
--
        --支払条件の必須チェック
        IF (lv_payment_term_id = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --支払条件必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_payment_term_id
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --支払条件が-でない場合
        IF (lv_payment_term_id <> cv_null_bar) THEN
          --支払条件存在チェック
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_id )
          LOOP
            lv_payment_term_id_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_term_id_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --支払条件存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_id
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_id
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --支払条件型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_payment_term_id  --支払条件
                                              ,lv_payment_term_id  --支払条件
                                              ,8                   --項目長
                                              ,NULL                --項目長（小数点以下）
                                              ,cv_null_ok          --必須フラグ
                                              ,cv_element_vc2      --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf      --エラーバッファ
                                              ,lv_item_retcode     --エラーコード
                                              ,lv_item_errmsg);    --エラーメッセージ
          --支払条件型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --支払条件エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_id
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_id
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --第2支払条件取得
        lv_payment_term_second := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- Ver1.10 mod start
--                                                                         ,21);
                                                                         ,16);
-- Ver1.10 mod end
        --第2支払条件が-でない場合
        IF (lv_payment_term_second <> cv_null_bar) THEN
          --第2支払条件存在チェック
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_second )
          LOOP
            lv_payment_second_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_second_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --第2支払条件存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_second
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_second
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --第2支払条件型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_payment_term_second  --第2支払条件
                                              ,lv_payment_term_second  --第2支払条件
                                              ,8                       --項目長
                                              ,NULL                    --項目長（小数点以下）
                                              ,cv_null_ok              --必須フラグ
                                              ,cv_element_vc2          --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf          --エラーバッファ
                                              ,lv_item_retcode         --エラーコード
                                              ,lv_item_errmsg);        --エラーメッセージ
          --第2支払条件型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --第2支払条件エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_second
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_second
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --第3支払条件取得
        lv_payment_term_third  := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- Ver1.10 mod start
--                                                                         ,22);
                                                                         ,17);
-- Ver1.10 mod end
        --第3支払条件が-でない場合
        IF (lv_payment_term_third <> cv_null_bar) THEN
          --第3支払条件存在チェック
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_third )
          LOOP
            lv_payment_third_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_third_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --第3支払条件存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_third
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_third
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --第3支払条件型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_payment_term_third  --第3支払条件
                                              ,lv_payment_term_third  --第3支払条件
                                              ,8                      --項目長
                                              ,NULL                   --項目長（小数点以下）
                                              ,cv_null_ok             --必須フラグ
                                              ,cv_element_vc2         --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf         --エラーバッファ
                                              ,lv_item_retcode        --エラーコード
                                              ,lv_item_errmsg);       --エラーメッセージ
          --第3支払条件型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --第3支払条件エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_third
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_third
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --チェーン店コード（販売先）取得
        lv_sales_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- Ver1.10 mod start
--                                                                      ,23);
                                                                      ,44);
-- Ver1.10 mod end
        --チェーン店コード（販売先）の必須チェック
        IF (lv_sales_chain_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --チェーン店コード（販売先）必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_sales_chain_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --チェーン店コード（販売先）が-でない場合
        IF (lv_sales_chain_code <> cv_null_bar) THEN
          --チェーン店コード（販売先）存在チェック
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_sales_chain_code )
          LOOP
            lv_sales_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_sales_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --チェーン店コード（販売先）チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_sales_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_sales_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --チェーン店コード（販売先）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_sales_chain_code  --チェーン店コード（販売先）
                                              ,lv_sales_chain_code  --チェーン店コード（販売先）
                                              ,9                    --項目長
                                              ,NULL                 --項目長（小数点以下）
                                              ,cv_null_ok           --必須フラグ
                                              ,cv_element_vc2       --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf       --エラーバッファ
                                              ,lv_item_retcode      --エラーコード
                                              ,lv_item_errmsg);     --エラーメッセージ
          --チェーン店コード（販売先）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --チェーン店コード（販売先）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_sales_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_sales_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --チェーン店コード（納品先）取得
        lv_delivery_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- Ver1.10 mod start
--                                                                         ,25);
                                                                         ,46);
-- Ver1.10 mod end
        --チェーン店コード（納品先）の必須チェック
        IF (lv_delivery_chain_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --チェーン店コード（納品先）必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_chain_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --チェーン店コード（納品先）が-でない場合
        IF (lv_delivery_chain_code <> cv_null_bar) THEN
          --チェーン店コード（納品先）存在チェック
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_delivery_chain_code )
          LOOP
            lv_deliv_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_deliv_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --チェーン店コード（納品先）チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_delivery_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_delivery_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --チェーン店コード（納品先）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_delivery_chain_code  --チェーン店コード（納品先）
                                              ,lv_delivery_chain_code  --チェーン店コード（納品先）
                                              ,9                       --項目長
                                              ,NULL                    --項目長（小数点以下）
                                              ,cv_null_ok              --必須フラグ
                                              ,cv_element_vc2          --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf          --エラーバッファ
                                              ,lv_item_retcode         --エラーコード
                                              ,lv_item_errmsg);        --エラーメッセージ
          --チェーン店コード（納品先）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --チェーン店コード（納品先）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_delivery_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_delivery_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --チェーン店コード（政策用）取得
        lv_policy_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.10 mod start
--                                                                       ,27);
                                                                       ,48);
-- Ver1.10 mod end
        --チェーン店コード（政策用）が-でない場合
        IF (lv_policy_chain_code <> cv_null_bar) THEN
          --チェーン店コード（政策用）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_policy_chain_code  --チェーン店コード（政策用）
                                              ,lv_policy_chain_code  --チェーン店コード（政策用）
                                              ,30                    --項目長
                                              ,NULL                  --項目長（小数点以下）
                                              ,cv_null_ok            --必須フラグ
                                              ,cv_element_vc2        --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf        --エラーバッファ
                                              ,lv_item_retcode       --エラーコード
                                              ,lv_item_errmsg);      --エラーメッセージ
          --チェーン店コード（政策用）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --チェーン店コード（政策用）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_policy_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_policy_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
--
        --紹介者チェーン1取得
        lv_intro_chain_code1 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.10 mod start
--                                                                       ,28);
                                                                       ,49);
-- Ver1.10 mod end
        --紹介者チェーン1が-でない場合
        IF (lv_intro_chain_code1 <> cv_null_bar) THEN
          --紹介者チェーン1型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_intro_chain_code1 --紹介者チェーン1
                                              ,lv_intro_chain_code1 --紹介者チェーン1
                                              ,30                   --項目長
                                              ,NULL                 --項目長（小数点以下）
                                              ,cv_null_ok           --必須フラグ
                                              ,cv_element_vc2       --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf       --エラーバッファ
                                              ,lv_item_retcode      --エラーコード
                                              ,lv_item_errmsg);     --エラーメッセージ
          --紹介者チェーン1型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --紹介者チェーン1エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_intro_chain_code1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_intro_chain_code1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --控除用チェーンコード取得
        lv_intro_chain_code2 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.10 mod start
--                                                                       ,29);
                                                                       ,50);
-- Ver1.10 mod end
        --控除用チェーンコードが-でない場合
        IF (lv_intro_chain_code2 <> cv_null_bar) THEN
-- Ver1.23 add start
          lv_dedu_chain_code    :=  xxccp_common_pkg.get_msg(
                                      iv_application   =>  gv_xxcmm_msg_kbn      -- アプリケーション短縮名
                                     ,iv_name          =>  cv_intro_chain_code2  -- メッセージコード
                                    );
          --控除用チェーンコード存在チェック
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_intro_chain_code2 )
          LOOP
            lv_dedu_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_dedu_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
-- Ver1.24 add start
            lv_retcode        := cv_status_error;
-- Ver1.24 add end
            --控除用チェーンコードチェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => lv_dedu_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_intro_chain_code2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- Ver1.23 add end
          --控除用チェーンコード型・桁数チェック
-- Ver1.23 mod start
--          xxccp_common_pkg2.upload_item_check( cv_intro_chain_code2 --紹介者チェーン2
          xxccp_common_pkg2.upload_item_check( lv_dedu_chain_code   --控除用チェーンコード
-- Ver1.23 mod end
                                              ,lv_intro_chain_code2 --控除用チェーンコード
-- Ver1.23 mod start
--                                              ,30                   --項目長
                                              ,9                    --項目長
-- Ver1.23 mod end
                                              ,NULL                 --項目長（小数点以下）
                                              ,cv_null_ok           --必須フラグ
                                              ,cv_element_vc2       --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf       --エラーバッファ
                                              ,lv_item_retcode      --エラーコード
                                              ,lv_item_errmsg);     --エラーメッセージ
          --控除用チェーンコード型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --控除用チェーンコードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
-- Ver1.23 mod start
--                            ,iv_token_value2 => cv_intro_chain_code2
                            ,iv_token_value2 => lv_dedu_chain_code
-- Ver1.23 mod end
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_intro_chain_code2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
--Ver1.25 add start
        -- 控除用チェーンコードがNULLでない場合、変更チェック
        IF (lv_intro_chain_code2 IS NOT NULL ) THEN
          -- 控除用チェーンコード取得カーソル
          << get_intro_chain_code2_loop >>
          FOR get_intro_chain_code2_rec IN get_intro_chain_code2_cur( lv_customer_code )
          LOOP
            lt_intro_chain_code2_bef := get_intro_chain_code2_rec.intro_chain_code2;
          END LOOP get_intro_chain_code2_loop;
--
          -- 控除用チェーンコードが変更された場合
          IF ( lv_intro_chain_code2 <> NVL(lt_intro_chain_code2_bef ,cv_null_bar) ) THEN
            -- 対象データ取得カーソル
            OPEN  check_dedu_chain_cur( lv_customer_code );
            FETCH check_dedu_chain_cur BULK COLLECT INTO gt_recon_slip_num_tab;
            CLOSE check_dedu_chain_cur;
            --控除消込ヘッダー情報の消込ステータスチェックエラー時
            <<check_dedu_chain>>
            FOR i IN 1..gt_recon_slip_num_tab.COUNT LOOP
              IF(i < gt_recon_slip_num_tab.COUNT) THEN
                lv_recon_slip_num := SUBSTRB(lv_recon_slip_num  || gt_recon_slip_num_tab(i).recon_slip_num || ',',1,2000);
              ELSE
                lv_recon_slip_num := SUBSTRB(lv_recon_slip_num  || gt_recon_slip_num_tab(i).recon_slip_num,1,2000);
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
--
                --控除消込ヘッダー情報の消込ステータスチェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_dedu_chain_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_dedu_chain_code
                                ,iv_token_value2 => lt_intro_chain_code2_bef
                                ,iv_token_name3  => cv_token_recon_slip_num
                                ,iv_token_value3 => lv_recon_slip_num
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END LOOP check_dedu_chain;
          END IF;
        END IF;
--Ver1.25 add end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
--
        --チェーン店コード（ＥＤＩ）取得
        lv_edi_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                    ,28);
-- Ver1.10 mod start
--                                                                    ,30);
                                                                    ,40);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --チェーン店コード（ＥＤＩ）が-でない場合
        IF (lv_edi_chain_code <> cv_null_bar) THEN
          --チェーン店コード（ＥＤＩ）存在チェック
          << check_edi_chain_loop >>
          FOR check_edi_chain_rec IN check_edi_chain_cur( lv_edi_chain_code )
          LOOP
            lv_edi_chain_mst := check_edi_chain_rec.edi_chain_code;
          END LOOP check_edi_chain_loop;
          IF (lv_edi_chain_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --チェーン店コード（ＥＤＩ）存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_edi_chain
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_edi_chain_code
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_addon_cust_mst
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.10 add start
            --チェーン店コード(EDI)チェックフラグFALSE
            lb_cs_code_chk_flg := FALSE;
-- Ver1.10 add end
          END IF;
          --チェーン店コード（ＥＤＩ）型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_edi_chain       --チェーン店コード（ＥＤＩ）
                                              ,lv_edi_chain_code  --チェーン店コード（ＥＤＩ）
                                              ,4                  --項目長
                                              ,NULL               --項目長（小数点以下）
                                              ,cv_null_ok         --必須フラグ
                                              ,cv_element_vc2     --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf     --エラーバッファ
                                              ,lv_item_retcode    --エラーコード
                                              ,lv_item_errmsg);   --エラーメッセージ
          --チェーン店コード（ＥＤＩ）型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --チェーン店コード（ＥＤＩ）エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_edi_chain
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_edi_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
-- Ver1.10 add start
            --チェーン店コード(EDI)チェックフラグFALSE
            lb_cs_code_chk_flg := FALSE;
-- Ver1.10 add end
          END IF;
        END IF;
-- Ver1.10 add start
        --チェーン店コード(EDI)の妥当性チェックOKの場合、更新値を取得
        IF (lb_cs_code_chk_flg = TRUE)
        THEN
          -- チェック用に顧客追加情報の現在値を取得
          << get_xca_info_loop >>
          FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
          LOOP
            lt_chain_store_code_bef  := get_xca_info_rec.chain_store_code;
          END LOOP get_xca_info_loop;
          --
          --変更値が'-'の場合
          IF (lv_edi_chain_code = cv_null_bar)
          THEN
            lt_chain_store_code_aft := NULL;
          --変更値がNULLの場合
          ELSIF (lv_edi_chain_code IS NULL)
          THEN
            --更新前の値を設定
            lt_chain_store_code_aft := lt_chain_store_code_bef;
          ELSE
            --CSVの値を設定
            lt_chain_store_code_aft := lv_edi_chain_code;
          END IF;
        END IF;
-- Ver1.10 add end
--
        --店舗コード取得
        lv_store_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                ,29);
-- Ver1.10 mod start
--                                                                ,31);
                                                                ,41);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --店舗コードが-でない場合
        IF (lv_store_code <> cv_null_bar) THEN
          --店舗コード型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_store_code     --店舗コード
                                              ,lv_store_code     --店舗コード
                                              ,10                --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --店舗コード型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --店舗コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_store_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_store_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --郵便番号取得
        lv_postal_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                 ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                 ,31);
-- Ver1.10 mod start
--                                                                 ,33);
                                                                 ,7);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --郵便番号の必須チェック
        IF (lv_postal_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --郵便番号必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_postal_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --郵便番号取得が-でない場合
        IF (lv_postal_code <> cv_null_bar) THEN
          --郵便番号型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_postal_code    --郵便番号
                                              ,lv_postal_code    --郵便番号
                                              ,7                 --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --郵便番号型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --郵便番号エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_postal_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_postal_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          --郵便番号半角数字7桁チェック
          IF (xxccp_common_pkg.chk_number(lv_postal_code) = FALSE)
            OR (LENGTHB(lv_postal_code) <> 7)
          THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --郵便番号チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_postal_code_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_postal_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_postal_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --都道府県取得
        lv_state := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                           ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                           ,32);
-- Ver1.10 mod start
--                                                           ,34);
                                                           ,8);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --都道府県の必須チェック
        IF (lv_state = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --都道府県必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_state
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --都道府県取得が-でない場合
        IF (lv_state <> cv_null_bar) THEN
          --都道府県型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_state          --都道府県
                                              ,lv_state          --都道府県
                                              ,30                --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --都道府県型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --都道府県エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_state
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_state
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- 全角文字チェック
          IF (xxccp_common_pkg.chk_double_byte(lv_state) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --全角文字チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_state
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_state
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --市・区取得
        lv_city := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                          ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                          ,33);
-- Ver1.10 mod start
--                                                          ,35);
                                                          ,9);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --市・区の必須チェック
        IF (lv_city = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --市・区必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_city
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --市・区取得が-でない場合
        IF (lv_city <> cv_null_bar) THEN
          --市・区型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_city           --市・区
                                              ,lv_city           --市・区
                                              ,30                --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --市・区型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --市・区エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_city
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_city
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- 全角文字チェック
          IF (xxccp_common_pkg.chk_double_byte(lv_city) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --全角文字チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_city
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_city
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --住所1取得
        lv_address1 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                              ,34);
-- Ver1.10 mod start
--                                                              ,36);
                                                              ,10);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --住所1の必須チェック
        IF (lv_address1 = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --住所1必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address1
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --住所1取得が-でない場合
        IF (lv_address1 <> cv_null_bar) THEN
          --住所1型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_address1       --住所1
                                              ,lv_address1       --住所1
                                              ,240               --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --住所1型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --住所1エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- 全角文字チェック
          IF (xxccp_common_pkg.chk_double_byte(lv_address1) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --全角文字チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --住所2取得
        lv_address2 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                              ,35);
-- Ver1.10 mod start
--                                                              ,37);
                                                              ,11);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --住所2取得が-でない場合
        IF (lv_address2 <> cv_null_bar) THEN
          --住所2型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_address2       --住所2
                                              ,lv_address2       --住所2
                                              ,240               --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --住所2型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --住所2エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address2
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- 全角文字チェック
          IF (xxccp_common_pkg.chk_double_byte(lv_address2) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --全角文字チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address2
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --地区コード取得
        lv_address3 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                              ,36);
-- Ver1.10 mod start
--                                                              ,38);
                                                              ,12);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --地区コードの必須チェック
        IF (lv_address3 = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --地区コード必須エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address3
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --地区コードが-でない場合
        IF (lv_address3 <> cv_null_bar) THEN
          --地区コード存在チェック
          << check_cust_chiku_code_loop >>
          FOR check_cust_chiku_code_rec IN check_cust_chiku_code_cur( lv_address3 )
          LOOP
            lv_cust_chiku_code_mst := check_cust_chiku_code_rec.cust_chiku_code;
          END LOOP check_cust_chiku_code_loop;
          IF (lv_cust_chiku_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --地区コード存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address3
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address3
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --地区コード型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_address3       --地区コード
                                              ,lv_address3       --地区コード
                                              ,5                 --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --地区コード型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --地区コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address3
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address3
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        IF (lv_customer_class = cv_trust_corp) THEN
          --顧客法人情報マスタ存在チェック
          IF (ln_cust_id IS NOT NULL) THEN
            --顧客法人情報マスタ存在チェック
            << check_cust_corp_loop >>
            FOR check_cust_corp_rec IN check_cust_corp_cur( ln_cust_id )
            LOOP
              ln_cust_corp_mst := check_cust_corp_rec.customer_id;
            END LOOP check_cust_corp_loop;
          END IF;
          IF (ln_cust_corp_mst IS NULL)THEN
              --顧客法人情報マスタ情報エラー
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --顧客法人情報マスタ存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_corp_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
          END IF;
          --与信限度額取得（法人顧客のみ）
          lv_credit_limit := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- Ver1.10 mod start
--                                                                    ,12);
-- Ver1.14 mod start
--                                                                    ,78);
-- Ver1.16 mod start
--                                                                    ,79);

-- Ver1.27 mod start
--                                                                    ,81);
                                                                    ,82);
-- Ver1.27 mod end
-- Ver1.16 mod end
-- Ver1.14 mod end
-- Ver1.10 mod end
          --与信限度額の必須チェック
          IF (lv_credit_limit = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --与信限度額必須エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_required_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_credit_limit
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          ELSE
            --与信限度額型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_credit_limit   --与信限度額
                                                ,lv_credit_limit   --与信限度額
                                                ,11                --項目長
                                                ,0                 --項目長（小数点以下）
                                                ,cv_null_ok        --必須フラグ
                                                ,cv_element_num    --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf    --エラーバッファ
                                                ,lv_item_retcode   --エラーコード
                                                ,lv_item_errmsg);  --エラーメッセージ
            --与信限度額型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --与信限度額エラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_credit_limit
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_credit_limit
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --型・桁数正常時のみ数値として扱い、与信限度額数値範囲チェック
              ln_credit_limit := TO_NUMBER(lv_credit_limit);
              IF  ((ln_credit_limit < 0)
                OR (ln_credit_limit > 99999999999)) THEN
                --与信限度額エラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_trust_val_invalid
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_credit_limit
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_credit_limit
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
          --判定区分取得（法人顧客のみ）
          lv_decide_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- Ver1.10 mod start
--                                                                  ,13);
-- Ver1.14 mod start
--                                                                  ,79);
-- Ver1.16 mod start
--                                                                  ,80);
-- Ver1.21 mod start
--                                                                  ,82);
-- Ver1.27 mod start
--                                                                  ,83);
                                                                  ,84);
-- Ver1.27 mod end
-- Ver1.21 mod end
-- Ver1.16 mod end
-- Ver1.14 mod end
-- Ver1.10 mod end
          --判定区分の必須チェック
          IF (lv_decide_div = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --判定区分必須エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_required_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_decide
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --判定区分が-でない場合
          IF (lv_decide_div <> cv_null_bar) THEN
            --判定区分存在チェック
            << check_decide_div_loop >>
            FOR check_decide_div_rec IN check_decide_div_cur( lv_decide_div )
            LOOP
              lv_decide_div_mst := check_decide_div_rec.decide_div;
            END LOOP check_decide_div_loop;
            IF (lv_decide_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --判定区分存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_decide
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_decide_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --判定区分型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_decide         --判定区分
                                                ,lv_decide_div     --判定区分
                                                ,1                 --項目長
                                                ,NULL              --項目長（小数点以下）
                                                ,cv_null_ok        --必須フラグ
                                                ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf    --エラーバッファ
                                                ,lv_item_retcode   --エラーコード
                                                ,lv_item_errmsg);  --エラーメッセージ
            --判定区分型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --判定区分エラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_decide
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_decide_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            END IF;
          END IF;
        END IF;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
        -- 請求書用コード取得
        lv_invoice_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                  ,37);
-- Ver1.10 mod start
--                                                                  ,39);
                                                                  ,52);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --請求書用コード型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_invoice_code   --請求書用コード
                                            ,lv_invoice_code   --請求書用コード
                                            ,9                 --項目長
                                            ,NULL              --項目長（小数点以下）
                                            ,cv_null_ok        --必須フラグ
                                            ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf    --エラーバッファ
                                            ,lv_item_retcode   --エラーコード
                                            ,lv_item_errmsg);  --エラーメッセージ
        --請求書用コード型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --請求書用コードエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_invoice_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_invoice_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
-- Ver1.15 add start
          lb_invoice_chk_flg := FALSE;
-- Ver1.15 add end
        END IF;
        --
        -- 顧客区分'10'の場合のみエラーチェックを行う
        IF (lv_cust_customer_class = cv_kokyaku_kbn) THEN
-- Ver1.15 add start
          IF ( lb_invoice_chk_flg = TRUE ) THEN
            --顧客追加情報の現在値を取得
            << get_xca_info_loop >>
            FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
            LOOP
              lt_invoice_code_bef := get_xca_info_rec.invoice_code;
            END LOOP get_xca_info_loop;
--
            --請求書用コードの更新値を取得
            IF ( lv_invoice_code = cv_null_bar )
            THEN
              lt_invoice_code_aft := NULL;
            ELSIF ( lv_invoice_code IS NULL )
            THEN
              lt_invoice_code_aft := lt_invoice_code_bef;
            ELSE
              lt_invoice_code_aft := lv_invoice_code;
            END IF;
          END IF;
-- Ver1.15 add end
          -- 請求書用コードの必須チェック
          -- 請求書用必須フラグが'Y'の場合、入力必須
-- Ver1.15 mod start
--          IF (lv_invoice_code = cv_null_bar)
          IF ( lt_invoice_code_aft IS NULL )
-- Ver1.15 mod end
            AND (lv_invoice_required_flag = cv_yes)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書用コード相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_invoice_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_invoice_kbn
                            ,iv_token_name3  => cv_cond_col_val
-- Ver1.15 mod start
--                            ,iv_token_value3 => lv_invoice_class
                            ,iv_token_value3 => lt_invoice_class_aft
-- Ver1.15 mod end
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.15 add start
            lb_invoice_chk_flg := FALSE;
-- Ver1.15 add end
          END IF;
          --請求書用コードが-でない場合
-- Ver1.15 mod start
--          IF (lv_invoice_code <> cv_null_bar) THEN
          IF ( lt_invoice_code_aft IS NOT NULL ) THEN
-- Ver1.15 mod end
            --請求書用コード存在チェック
            << check_invoice_class_loop >>
-- Ver1.15 mod start
--            FOR check_invoice_code_rec IN check_invoice_code_cur( lv_invoice_code )
            FOR check_invoice_code_rec IN check_invoice_code_cur( lt_invoice_code_aft )
-- Ver1.15 mod end
            LOOP
              ln_invoice_code_mst     := check_invoice_code_rec.cust_id;
            END LOOP check_invoice_class_loop;
            IF (ln_invoice_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --請求書用コード存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_invoice_code
                              ,iv_token_name3  => cv_input_val
-- Ver1.15 mod start
--                              ,iv_token_value3 => lv_invoice_code
                              ,iv_token_value3 => lt_invoice_code_aft
-- Ver1.15 mod end
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_cust_acct_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
-- Ver1.15 add start
              lb_invoice_chk_flg := FALSE;
-- Ver1.15 add end
            END IF;
          END IF;
        END IF;
-- Ver1.27 add start
        -- 請求書消費税積上げ計算方式取得
        lv_invoice_tax_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,53);
        --請求書消費税積上げ計算方式 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_invoice_tax_div  --請求書消費税積上げ計算方式
                                            ,lv_invoice_tax_div  --請求書消費税積上げ計算方式
                                            ,1                   --項目長
                                            ,NULL                --項目長（小数点以下）
                                            ,cv_null_ok          --必須フラグ
                                            ,cv_element_vc2      --属性（0・検証なし）
                                            ,lv_item_errbuf      --エラーバッファ
                                            ,lv_item_retcode     --エラーコード
                                            ,lv_item_errmsg);    --エラーメッセージ
        --請求書消費税積上げ計算方式 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --請求書消費税積上げ計算方式エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_invoice_tax_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_invoice_tax_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        ELSE
          lv_invoice_tax_div := UPPER(lv_invoice_tax_div);
          --請求書消費税積上げ計算方式 Yes/No（Y/N）のコードチェックエラー時
          IF (NVL(lv_invoice_tax_div,cv_no) <> cv_no AND NVL(lv_invoice_tax_div,cv_no) <> cv_yes) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求書消費税積上げ計算方式エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_msg_invoice_tax_div_err
                            ,iv_token_name1  => cv_invoice_tax_div_tk
                            ,iv_token_value1 => lv_invoice_tax_div
                            ,iv_token_name2  => cv_cust_code
                            ,iv_token_value2 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
           END IF;
        END IF;
-- Ver1.27 add end
        --
        -- 業種取得
        lv_industry_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                  ,38);
-- Ver1.10 mod start
--                                                                  ,40);
                                                                  ,26);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --業種型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_industry_div   --業種
                                            ,lv_industry_div   --業種
                                            ,2                 --項目長
                                            ,NULL              --項目長（小数点以下）
                                            ,cv_null_ok        --必須フラグ
                                            ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf    --エラーバッファ
                                            ,lv_item_retcode   --エラーコード
                                            ,lv_item_errmsg);  --エラーメッセージ
        --業種型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --業種エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_industry_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_industry_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        --
        -- 顧客区分'10','12','13','14','15','16','17'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          -- 業種の必須チェック
          -- 顧客区分'10'(顧客)、'12'(上様顧客)、'15'(店舗営業)の場合、入力必須
          IF (lv_industry_div = cv_null_bar)
            AND (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn, cv_tenpo_kbn ) )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --業種相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_industry_div
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --業種が-でない場合
          IF (lv_industry_div <> cv_null_bar) THEN
            --業種存在チェック
            << check_industry_div_loop >>
            FOR check_lookup_type_rec IN check_lookup_type_cur( lv_industry_div, cv_gyotai_kbn )
            LOOP
              lv_industry_div_mst     := check_lookup_type_rec.lookup_code;
            END LOOP check_industry_div_loop;
            IF (lv_industry_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --業種存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_industry_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_industry_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- 請求拠点取得
        lv_bill_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                    ,39);
-- Ver1.10 mod start
--                                                                    ,41);
                                                                    ,37);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --請求拠点型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_bill_base_code --請求拠点
                                            ,lv_bill_base_code --請求拠点
                                            ,4                 --項目長
                                            ,NULL              --項目長（小数点以下）
                                            ,cv_null_ok        --必須フラグ
                                            ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf    --エラーバッファ
                                            ,lv_item_retcode   --エラーコード
                                            ,lv_item_errmsg);  --エラーメッセージ
        --請求拠点型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --請求拠点エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_bill_base_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_bill_base_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- 顧客区分'10','12','14','20','21'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_seikyusho_kbn, cv_toukatu_kbn )) THEN
          -- 請求拠点の必須チェック
          IF (lv_bill_base_code = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --請求拠点相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_bill_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --請求拠点が-でない場合
          IF (lv_bill_base_code <> cv_null_bar) THEN
            --請求拠点存在チェック
            << check_bill_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_bill_base_code )
            LOOP
              lv_bill_base_code_mst     := check_flex_value_rec.flex_value;
            END LOOP check_bill_base_code_loop;
            IF (lv_bill_base_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --請求拠点存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_bill_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_bill_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- 入金拠点取得
        lv_receiv_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                      ,40);
-- Ver1.10 mod start
--                                                                      ,42);
                                                                      ,38);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --入金拠点型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_receiv_base_code --入金拠点
                                            ,lv_receiv_base_code --入金拠点
                                            ,4                   --項目長
                                            ,NULL                --項目長（小数点以下）
                                            ,cv_null_ok          --必須フラグ
                                            ,cv_element_vc2      --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf      --エラーバッファ
                                            ,lv_item_retcode     --エラーコード
                                            ,lv_item_errmsg);    --エラーメッセージ
        --入金拠点型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --入金拠点エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_receiv_base_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_receiv_base_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- 顧客区分'10','12','14'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn)) THEN
          -- 入金拠点の必須チェック
          IF (lv_receiv_base_code = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --入金拠点相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_receiv_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --入金拠点が-でない場合
          IF (lv_receiv_base_code <> cv_null_bar) THEN
            --入金拠点存在チェック
            << check_receiv_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_receiv_base_code )
            LOOP
              lv_receiv_base_code_mst     := check_flex_value_rec.flex_value;
            END LOOP check_receiv_base_code_loop;
            IF (lv_receiv_base_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --入金拠点存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_receiv_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_receiv_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- 納品拠点取得
        lv_delivery_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                        ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                        ,41);
-- Ver1.10 mod start
--                                                                        ,43);
                                                                        ,36);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --納品拠点型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_delivery_base_code --納品拠点
                                            ,lv_delivery_base_code --納品拠点
                                            ,4                     --項目長
                                            ,NULL                  --項目長（小数点以下）
                                            ,cv_null_ok            --必須フラグ
                                            ,cv_element_vc2        --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf        --エラーバッファ
                                            ,lv_item_retcode       --エラーコード
                                            ,lv_item_errmsg);      --エラーメッセージ
        --納品拠点型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --納品拠点エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_base_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_delivery_base_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
-- Ver1.10 add start
          --納品拠点チェックフラグFALSE
          lb_db_code_chk_flg := FALSE;
-- Ver1.10 add end
        END IF;
        -- 顧客区分'10','12','14'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn)) THEN
          -- 納品拠点の必須チェック
          -- 顧客区分'10'(顧客)、'12'(上様顧客)の場合、入力必須
          IF (lv_delivery_base_code = cv_null_bar)
            AND (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn ) )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --納品拠点相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_delivery_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.10 add start
            --納品拠点チェックフラグFALSE
            lb_db_code_chk_flg := FALSE;
-- Ver1.10 add end
          END IF;
          --納品拠点が-でない場合
          IF (lv_delivery_base_code <> cv_null_bar) THEN
            --納品拠点存在チェック
            << check_delivery_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_delivery_base_code )
            LOOP
              lv_delivery_base_code_mst     := check_flex_value_rec.flex_value;
            END LOOP check_delivery_base_code_loop;
            IF (lv_delivery_base_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --納品拠点存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_delivery_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_delivery_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
-- Ver1.10 add start
              --納品拠点チェックフラグFALSE
              lb_db_code_chk_flg := FALSE;
-- Ver1.10 add end
            END IF;
          END IF;
--
          --納品拠点の妥当性チェックOKの場合、更新値を取得
          IF (lb_db_code_chk_flg = TRUE)
          THEN
            -- チェック用に顧客追加情報の現在値を取得
            << get_xca_info_loop >>
            FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
            LOOP
              lt_delivery_base_code_bef  := get_xca_info_rec.delivery_base_code;
            END LOOP get_xca_info_loop;
            --
            --変更値が'-'の場合
            IF (lv_delivery_base_code = cv_null_bar)
            THEN
              lt_delivery_base_code_aft := NULL;
            --変更値がNULLの場合
            ELSIF (lv_delivery_base_code IS NULL)
            THEN
              --更新前の値を設定
              lt_delivery_base_code_aft := lt_delivery_base_code_bef;
            ELSE
              --CSVの値を設定
              lt_delivery_base_code_aft := lv_delivery_base_code;
            END IF;
          END IF;
        END IF;
        --
--
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
        --顧客区分「10：顧客」「14：売掛管理先顧客」「19：百貨店伝区」の場合
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_urikake_kbn, cv_hyakkaten_kbn) ) THEN
          --
          --販売先本部担当拠点取得
          lv_sales_head_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                            ,cv_comma
-- Ver1.10 mod start
--                                                                            ,44);
                                                                            ,39);
-- Ver1.10 mod end
          --
          --CSVに設定された販売先本部担当拠点が任意の値の場合
          IF (lv_sales_head_base_code <> cv_null_bar) THEN
            --販売先本部担当拠点存在チェック
            << check_head_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_sales_head_base_code )
            LOOP
              lv_sales_head_base_code_mst := check_flex_value_rec.flex_value;
            END LOOP check_head_base_code_loop;
            IF (lv_sales_head_base_code_mst IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --販売先本部担当拠点参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_sales_head_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_sales_head_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          END IF;
        --
        END IF;
--
        --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
        --
          -- 獲得拠点コード 取得
          lv_cnvs_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- Ver1.10 mod start
--                                                                      ,45);
-- Ver1.27 mod start
--                                                                      ,64);
                                                                      ,65);
-- Ver1.27 mod end
-- Ver1.10 mod end
--
          -- 獲得営業員 取得
          lv_cnvs_business_person := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                            ,cv_comma
-- Ver1.10 mod start
--                                                                            ,46);
-- Ver1.27 mod start
--                                                                            ,65);
                                                                            ,66);
-- Ver1.27 mod end
-- Ver1.10 mod end
--
          -- 獲得拠点コード、獲得営業員のチェック
          --
          --CSVに設定された獲得拠点コードがNULLの場合
          IF ( lv_cnvs_base_code IS NULL ) THEN
            --
            --獲得拠点コードのDB存在チェック
            << check_db_base_code_loop >>
            FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
            LOOP
              lv_cnvs_base_code_mst1  := check_db_code_person_rec.cnvs_base_code;
            END LOOP check_db_base_code_loop;
            --
            --DBに設定された獲得拠点コードがNULLの場合
            IF (lv_cnvs_base_code_mst1 IS NULL) THEN
              --
              --CSVに設定された獲得営業員が'-'ではない場合(任意の値)
              IF ( lv_cnvs_business_person <> cv_null_bar ) THEN
              --
                --エラー対象
                lv_business_person_flag3 := cv_yes;
              --
              ELSIF ( lv_cnvs_business_person = cv_null_bar ) THEN
              --CSVに設定された獲得営業員が'-'の場合
                --
                --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上の場合、獲得営業員は必須
                IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                    TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
                    --エラー対象
                    lv_business_person_flag1 := cv_yes;
                END IF;
                --
              --
              END IF;
            --
            ELSE
            --DBに設定された獲得拠点コードが任意の値の場合
            --
              --CSVに設定された獲得営業員が'-'の場合
              IF ( lv_cnvs_business_person = cv_null_bar ) THEN
                --
                --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上の場合、獲得営業員は必須
                IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                    TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
                  --
                  --エラー対象
                  lv_business_person_flag1 := cv_yes;
                ELSE
                  --エラー対象
                  lv_business_person_flag2 := cv_yes;
                END IF;
              --
              END IF;
            --
            END IF;
          --
          ELSIF ( lv_cnvs_base_code = cv_null_bar ) THEN
          --CSVに設定された獲得拠点コードが'-'の場合
          --
            --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上の場合、獲得拠点コードは必須
            IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                 TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
              --エラー対象
              lv_base_code_flag1 := cv_yes;
              --
              --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上の場合、獲得営業員は必須
              IF ( lv_cnvs_business_person = cv_null_bar ) THEN
                --エラー対象
                lv_business_person_flag1 := cv_yes;
                --
              END IF;
            --
            ELSE
              --CSVに設定された獲得営業員がNULLの場合
              IF ( lv_cnvs_business_person IS NULL ) THEN
                --
                --獲得営業員のDB存在チェック
                << check_db_business_person_loop >>
                FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
                LOOP
                  lv_cnvs_business_person_mst1  := check_db_code_person_rec.cnvs_business_person;
                END LOOP check_db_business_person_loop;
                --
                --DBに設定された獲得営業員が任意の値の場合
                IF (lv_cnvs_business_person_mst1 IS NOT NULL) THEN
                  --
                  --エラー対象
                  lv_base_code_flag2 := cv_yes;
                END IF;
              --
              ELSIF ( lv_cnvs_business_person <> cv_null_bar ) THEN
              --CSVに設定された獲得営業員が'-'ではない場合(任意の値)
                --
                --エラー対象
                lv_base_code_flag2 := cv_yes;
              --
              END IF;
            --
            END IF;
          --
          ELSE 
          --CSVに設定された獲得拠点コードに任意の値が設定されている場合
          --
            --CSVに設定された獲得営業員がNULLの場合
            IF ( lv_cnvs_business_person IS NULL ) THEN
              --
              --獲得営業員のDB存在チェック
              << check_db_business_person_loop >>
              FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
              LOOP
                lv_cnvs_business_person_mst1  := check_db_code_person_rec.cnvs_business_person;
              END LOOP check_db_business_person_loop;
              --
              --DBに設定された獲得営業員がNULLの場合
              IF (lv_cnvs_business_person_mst1 IS NULL) THEN
                --
                --エラー対象
                lv_base_code_flag3 := cv_yes;
              END IF;
            --
            ELSIF ( lv_cnvs_business_person = cv_null_bar ) THEN
            --CSVに設定された獲得営業員が'-'の場合
              --
              --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上の場合、獲得営業員は必須
              IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                   TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
              --
                --エラー対象
                lv_business_person_flag1 := cv_yes;
              --
              ELSE
                --エラー対象
                lv_business_person_flag2 := cv_yes;
              END IF;
            --
            END IF;
          --
          END IF;
--
          --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上で、
          --獲得拠点コードに'-'を設定した場合、エラーとする
          --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上で、
          --獲得営業員に'-'を設定した場合、エラーとする
          IF ( lv_base_code_flag1 = cv_yes OR lv_business_person_flag1 = cv_yes ) THEN
          --
            --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上で、
            --獲得拠点コードに'-'を設定した場合、エラーとする
            IF ( lv_base_code_flag1 = cv_yes ) THEN
              --エラーメッセージの設定
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --顧客区分ステータスチェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_cust_class_kbn_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_cnvs_base_code
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --
            --顧客区分「10：顧客」かつ顧客ステータス「30：承認済」以上で、
            --獲得営業員に'-'を設定した場合、エラーとする
            IF (lv_business_person_flag1 = cv_yes) THEN
              --
              --エラーメッセージの設定
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --顧客区分ステータスチェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_cust_class_kbn_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_cnvs_business_person
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          --
          ELSIF (lv_base_code_flag2 = cv_yes) THEN
          --CSVに設定された獲得拠点コードが'-'で、
          --CSVに設定された獲得営業員、またはDBに登録された獲得営業員が任意の値の場合エラーとする
            --
            --エラーメッセージの設定
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --獲得拠点営業員相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_code_person_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_business_person
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_business_person_flag2 = cv_yes) THEN
          --CSVに設定された獲得営業員が'-'の場合、
          --CSVに設定された獲得拠点コード、またはDBに登録された獲得拠点コードが任意の値の場合エラーとする
            --
            --エラーメッセージの設定
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --獲得拠点営業員相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_code_person_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_business_person
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_base_code
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_base_code_flag3 = cv_yes) THEN
          --CSVに設定された獲得拠点コードが任意の値で、
          --CSVに設定された獲得営業員がNULLで、DBに登録された獲得営業員がNULLの場合エラーとする
            --
            --エラーメッセージの設定
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --未登録チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_intro_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_business_person
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_business_person_flag3 = cv_yes) THEN
          --CSVに設定された獲得営業員が任意の値で、
          --CSVに設定された獲得拠点コードがNULLで、DBに登録された獲得拠点コードがNULLの場合エラーとする
            --
            --エラーメッセージの設定
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --未登録チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_intro_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_business_person
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_base_code
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSE
          --
            --CSVに設定された獲得拠点がNULLの場合
            IF ( lv_cnvs_base_code IS NULL ) THEN
            --
              --DBに設定された獲得拠点が任意の値の場合
              IF ( lv_cnvs_base_code_mst1 IS NOT NULL ) THEN
              --
                --CSVに設定された獲得従業員がNULLではない、かつ'-'以外の場合(任意の値)
                IF ( lv_cnvs_business_person <> cv_null_bar ) THEN
                --
                  --拠点コードと獲得営業員の紐付き権限用チェック
                  << check_db_code_relation_loop >>
                  FOR check_db_code_relation_rec IN check_db_code_relation_cur( lv_cnvs_base_code_mst1,
                                                                                lv_cnvs_business_person )
                  LOOP
                    lv_cnvs_business_person_mst2  := check_db_code_relation_rec.new_employee_number;
                  END LOOP check_db_code_relation_loop;
                  --
                  --職責管理フラグが'N'の場合
                  IF (gv_resp_flag = cv_no) THEN
                  --
                    --DBの獲得拠点でCSVに設定された獲得従業員が取得できない場合
                    IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                    --
                      --拠点コードと獲得営業員の紐付き権限用チェック
                      << check_db_code_rel_auth_loop >>
                      FOR check_db_code_rel_auth_rec IN check_db_code_rel_auth_cur( lv_cnvs_base_code_mst1,
                                                                                    lv_cnvs_business_person )
                      LOOP
                        lv_cnvs_business_person_mst2  := check_db_code_rel_auth_rec.old_employee_number;
                      END LOOP check_db_code_rel_auth_loop;
                      --
                      --DBの獲得拠点でCSVに設定された獲得従業員が取得できない場合(権限用)
                      IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                        --
                        --エラー対象
                        lv_business_person_flag4 := cv_yes;
                      END IF;
                    --
                    END IF;
                  --
                  ELSE
                  --職責管理フラグが'Y'の場合
                    --
                    --DBの獲得拠点でCSVに設定された獲得従業員が取得できない場合
                    IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                      --
                      --エラー対象
                      lv_business_person_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                --
                END IF;
              --
              END IF;
            --
            ELSIF ( lv_cnvs_base_code <> cv_null_bar ) THEN
            --CSVに設定された獲得拠点が'-'以外の場合(任意の値)
            --
              --CSVに設定された獲得従業員がNULLの場合
              IF ( lv_cnvs_business_person IS NULL ) THEN
              --
                --DBに設定された獲得営業員が任意の値の場合
                IF ( lv_cnvs_business_person_mst1 IS NOT NULL ) THEN
                --
                  --獲得営業員と拠点コードの紐付きチェック
                  << check_db_person_relation_loop >>
                  FOR check_db_person_relation_rec IN check_db_person_relation_cur( lv_cnvs_business_person_mst1 )
                  LOOP
                    lv_cnvs_base_code_mst2  := check_db_person_relation_rec.new_base_code;
                  END LOOP check_db_person_relation_loop;
                  --
                  --職責管理フラグが'N'の場合
                  IF (gv_resp_flag = cv_no) THEN
                  --
                    --CSVに設定された獲得拠点とDBの獲得従業員に紐付く獲得拠点が異なる場合
                    IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                    --
                      --獲得営業員と拠点コードの紐付き権限用チェック
                      << check_db_person_rel_auth_loop >>
                      FOR check_db_person_rel_auth_rec IN check_db_person_rel_auth_cur( lv_cnvs_business_person_mst1 )
                      LOOP
                        lv_cnvs_base_code_mst2  := check_db_person_rel_auth_rec.old_base_code;
                      END LOOP check_db_person_rel_auth_loop;
                      --
                      --CSVに設定された獲得拠点とDBの獲得従業員に紐付く獲得拠点が異なる場合(権限用)
                      IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                        --
                        --エラー対象
                        lv_base_code_flag4 := cv_yes;
                      END IF;
                    --
                    END IF;
                  --
                  ELSE
                  --職責管理フラグが'Y'の場合
                  --
                    --CSVに設定された獲得拠点とDBの獲得従業員に紐付く獲得拠点が異なる場合
                    IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                      --
                      --エラー対象
                      lv_base_code_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                --
                END IF;
              --
              ELSIF ( lv_cnvs_business_person <> cv_null_bar ) THEN
              --CSVに設定された獲得従業員が'-'以外の場合(任意の値)
              --
                --獲得営業員と拠点コードの紐付きチェック
                << check_db_person_relation_loop >>
                FOR check_db_person_relation_rec IN check_db_person_relation_cur( lv_cnvs_business_person )
                LOOP
                  lv_cnvs_base_code_mst2  := check_db_person_relation_rec.new_base_code;
                END LOOP check_db_person_relation_loop;
                --
                --拠点コードと獲得営業員の紐付き権限用チェック
                << check_db_code_relation_loop >>
                FOR check_db_code_relation_rec IN check_db_code_relation_cur( lv_cnvs_base_code,
                                                                              lv_cnvs_business_person )
                LOOP
                  lv_cnvs_business_person_mst2  := check_db_code_relation_rec.new_employee_number;
                END LOOP check_db_code_relation_loop;
                --
                --職責管理フラグが'N'の場合
                IF (gv_resp_flag = cv_no) THEN
                --
                  --CSVに設定された獲得拠点とCSVに設定された獲得従業員に紐付く獲得拠点が異なる場合
                  IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                  --
                    --獲得営業員と拠点コードの紐付き権限用チェック
                    << check_db_person_rel_auth_loop >>
                    FOR check_db_person_rel_auth_rec IN check_db_person_rel_auth_cur( lv_cnvs_business_person )
                    LOOP
                      lv_cnvs_base_code_mst2  := check_db_person_rel_auth_rec.old_base_code;
                    END LOOP check_db_person_rel_auth_loop;
                    --
                    --CSVに設定された獲得拠点とCSVに設定された獲得従業員に紐付く獲得拠点が異なる場合(権限用)
                    IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                      --
                      --エラー対象
                      lv_base_code_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                  --
                  --CSVに設定された獲得拠点獲得拠点でCSVに設定された獲得従業員が取得できない場合
                  IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                  --
                    --拠点コードと獲得営業員の紐付き権限用チェックチェック
                    << check_db_code_rel_auth_loop >>
                    FOR check_db_code_rel_auth_rec IN check_db_code_rel_auth_cur( lv_cnvs_base_code,
                                                                                  lv_cnvs_business_person )
                    LOOP
                      lv_cnvs_business_person_mst2 := check_db_code_rel_auth_rec.old_employee_number;
                    END LOOP check_db_code_rel_auth_loop;
                    --
                    --CSVに設定された獲得拠点でCSVに設定された獲得従業員が取得できない場合(権限用)
                    IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                      --
                      --エラー対象
                      lv_business_person_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                --
                ELSE
                --職責管理フラグが'Y'の場合
                --
                  --CSVに設定された獲得拠点とCSVに設定された獲得従業員に紐付く獲得拠点が異なる場合
                  IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                    --
                    --エラー対象
                    lv_base_code_flag4 := cv_yes;
                  END IF;
                  --
                  --CSVに設定された獲得拠点でCSVに設定された獲得従業員が取得できない場合
                  IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                    --
                    --エラー対象
                    lv_business_person_flag4 := cv_yes;
                  END IF;
                --
                END IF;
              --
              END IF;
            --
            END IF;
          --
            --CSVに設定された獲得拠点とDBの獲得従業員に紐付く獲得拠点が異なる場合
            --または、CSVに設定された獲得拠点とCSVに設定された獲得従業員に紐付く獲得拠点が異なる場合
            IF ( lv_base_code_flag4 = cv_yes ) THEN
              --エラーメッセージの設定
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --獲得拠点従業員紐付きチェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_code_relation_err_msg
                              ,iv_token_name1  => cv_input_val
                              ,iv_token_value1 => lv_cnvs_base_code
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --
            ELSIF ( lv_business_person_flag4 = cv_yes ) THEN
            --DBの獲得拠点でCSVに設定された獲得従業員が取得できない場合
            --または、CSVに設定された獲得拠点でCSVに設定された獲得従業員が取得できない場合
              --エラーメッセージの設定
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --獲得従業員拠点紐付きチェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_person_relation_err_msg
                              ,iv_token_name1  => cv_input_val
                              ,iv_token_value1 => lv_cnvs_business_person
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --
            END IF;
          --
          END IF;
--
        END IF;
--
        --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
          --
          --新規ポイント区分取得
          lv_new_point_div := xxccp_common_pkg.char_delim_partition(    lv_temp
                                                                       ,cv_comma
-- Ver1.10 mod start
--                                                                       ,47);
-- Ver1.27 mod start
--                                                                       ,66);
                                                                       ,67);
-- Ver1.27 mod end
-- Ver1.10 mod end
          --CSVに設定された新規ポイント区分が任意の値の場合
          IF (lv_new_point_div <> cv_null_bar) THEN
            --新規ポイント区分存在チェック
            << check_new_point_div_loop >>
            FOR check_new_point_div_rec IN check_new_point_div_cur( lv_new_point_div )
            LOOP
              lv_new_point_div_mst := check_new_point_div_rec.new_point_div;
            END LOOP check_new_point_div_loop;
            IF (lv_new_point_div_mst IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --新規ポイント区分参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_new_point_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_new_point_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          END IF;
        --
        END IF;
--
        --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
        --
          --新規ポイント取得
          lv_new_point     := xxccp_common_pkg.char_delim_partition(    lv_temp
                                                                       ,cv_comma
-- Ver1.10 mod start
--                                                                       ,48);
-- Ver1.27 mod start
--                                                                       ,67);
                                                                       ,68);
-- Ver1.27 mod end
-- Ver1.10 mod end
          --CSVに設定された新規ポイントが任意の値の場合
          IF ( lv_new_point <> cv_null_bar ) THEN
            --新規ポイント型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_new_point   --新規ポイント
                                                ,lv_new_point   --新規ポイント
                                                ,3                 --項目長
                                                ,0                 --項目長（小数点以下）
                                                ,cv_null_ok        --必須フラグ
                                                ,cv_element_num    --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf    --エラーバッファ
                                                ,lv_item_retcode   --エラーコード
                                                ,lv_item_errmsg);  --エラーメッセージ
            --新規ポイント型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --新規ポイントエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_new_point
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_new_point
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --型・桁数正常時のみ数値として扱い、新規ポイント数値範囲チェック
              ln_new_point := TO_NUMBER(lv_new_point);
              IF  ((ln_new_point < cn_point_min)
                OR (ln_new_point > cn_point_max)) THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --新規ポイントエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_new_point_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_new_point
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_new_point
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          --
          END IF;
        --
        END IF;
--
        --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
        --
          --紹介拠点取得
          lv_intro_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.10 mod start
--                                                                       ,49);
-- Ver1.27 mod start
--                                                                       ,68);
                                                                       ,69);
-- Ver1.27 mod end
-- Ver1.10 mod end
          --CSVに設定された紹介拠点が任意の値の場合
          IF (lv_intro_base_code <> cv_null_bar) THEN
            --紹介拠点存在チェック
            << check_intro_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_intro_base_code )
            LOOP
              lv_intro_base_code_mst1 := check_flex_value_rec.flex_value;
            END LOOP check_intro_base_code_loop;
            IF (lv_intro_base_code_mst1 IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --紹介拠点参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_intro_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_intro_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          END IF;
        --
        END IF;
--
        --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
          --
          --紹介営業員取得
          lv_intro_business_person := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                             ,cv_comma
-- Ver1.10 mod start
--                                                                             ,50);
-- Ver1.27 mod start
--                                                                             ,69);
                                                                             ,70);
-- Ver1.27 mod end
-- Ver1.10 mod end
          --CSVに設定された紹介営業員がNULLの場合
          IF ( lv_intro_business_person IS NULL ) THEN
          --
            --紹介営業員存在チェック
            << check_db_intro_person_loop >>
            FOR check_db_intro_person_rec IN check_db_intro_person_cur( lv_customer_code )
            LOOP
              lv_intro_business_person_mst1 := check_db_intro_person_rec.intro_business_person;
            END LOOP check_db_intro_person_loop;
            IF ( lv_intro_business_person_mst1 IS NOT NULL ) THEN
            --
              --獲得拠点コード、獲得営業員のチェックでエラーがない場合
              IF (  lv_base_code_flag1 IS NULL AND lv_business_person_flag1 IS NULL
                AND lv_base_code_flag2 IS NULL AND lv_business_person_flag2 IS NULL
                AND lv_base_code_flag3 IS NULL AND lv_business_person_flag3 IS NULL
                AND lv_base_code_flag4 IS NULL AND lv_business_person_flag4 IS NULL ) THEN
                --
                --CSVに設定された獲得営業員とDBに設定された紹介営業員が同じ場合
                IF ( lv_cnvs_business_person_mst2 = lv_intro_business_person_mst1 ) THEN
                --
                  lv_check_status   := cv_status_error;
                  lv_retcode        := cv_status_error;
                  --獲得営業員紹介者チェックエラーメッセージ取得
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => gv_xxcmm_msg_kbn
                                  ,iv_name         => cv_intro_person_err_msg
                                  ,iv_token_name1  => cv_cust_code
                                  ,iv_token_value1 => lv_customer_code
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.LOG
                    ,buff   => gv_out_msg
                  );
                --
                END IF;
              --
              END IF;
            --
            END IF;
          --
          ELSIF ( lv_intro_business_person <> cv_null_bar ) THEN
          --CSVに設定された紹介営業員取得が任意の値の場合
          --
            --CSVに設定された紹介拠点がNULLの場合
            IF ( lv_intro_base_code IS NULL ) THEN
            --
              --紹介拠点コード存在チェック
              << check_intro_base_code_loop >>
              FOR check_db_intro_base_code_rec IN check_db_intro_base_code_cur( lv_customer_code )
              LOOP
                lv_intro_base_code_mst2 := check_db_intro_base_code_rec.intro_base_code;
              END LOOP check_intro_base_code_loop;
              IF (lv_intro_base_code_mst2 IS NULL) THEN
                --エラー対象
                lv_int_bus_per_flag1 := cv_yes;
              --
              END IF;
            --
            ELSIF ( lv_intro_base_code = cv_null_bar ) THEN
            --CSVに設定された紹介拠点が'-'の場合
              --エラー対象
              lv_int_bus_per_flag1 := cv_yes;
            --
            END IF;
            --
            --CSVに設定された紹介営業員が任意の値で、
            --CSVに設定された紹介拠点がNULL、DBに登録された紹介拠点がNULLの場合
            --または、CSVに設定された紹介拠点が'-'の場合
            IF ( lv_int_bus_per_flag1 = cv_yes ) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --未登録チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_intro_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_intro_business_person
                              ,iv_token_name2  => cv_cond_col_name
                              ,iv_token_value2 => cv_intro_base_code
                              ,iv_token_name3  => cv_cust_code
                              ,iv_token_value3 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --
            ELSE
            --
              --紹介者マスタチェックカーソル
              << check_db_mst_person_loop >>
              FOR check_db_mst_person_rec IN check_db_mst_person_cur( lv_intro_business_person )
              LOOP
                lv_intro_business_person_mst2 := check_db_mst_person_rec.employee_number;
              END LOOP check_db_mst_person_loop;
              --
              IF ( lv_intro_business_person_mst2 IS NULL ) THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --紹介者マスタチェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_mst_intro_per_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              --
              ELSE
              --
                --獲得拠点コード、獲得営業員のチェックでエラーがない場合
                IF (  lv_base_code_flag1 IS NULL AND lv_business_person_flag1 IS NULL
                  AND lv_base_code_flag2 IS NULL AND lv_business_person_flag2 IS NULL
                  AND lv_base_code_flag3 IS NULL AND lv_business_person_flag3 IS NULL
                  AND lv_base_code_flag4 IS NULL AND lv_business_person_flag4 IS NULL ) THEN
                --
                  --CSVの獲得営業員がNULLの場合
                  IF (lv_cnvs_business_person IS NULL) THEN
                  --
                    --DBに獲得営業員が設定されている場合(CSVにはNULLが設定されている)
                    IF ( lv_cnvs_business_person_mst1 IS NOT NULL ) THEN
                      --
                      --DBに設定された獲得営業員とCSVに設定されている紹介営業員が同じ場合
                      IF ( lv_cnvs_business_person_mst1 = lv_intro_business_person ) THEN
                        --エラー対象
                        lv_int_bus_per_flag2 := cv_yes;
                      END IF;
                    --
                    ELSE
                      --獲得拠点コード、獲得営業員のCSVの両項目にNULLが設定されている場合、
                      --獲得営業員のDBに登録された値は取得されていない為、DBから取得する
                      --獲得営業員のDB存在チェック
                      << check_db_get_bus_per_loop >>
                      FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
                      LOOP
                        lv_cnvs_business_person_mst1  := check_db_code_person_rec.cnvs_business_person;
                      END LOOP check_db_get_bus_per_loop;
                      --
                      --DBに設定された獲得営業員とCSVに設定されている紹介営業員が同じ場合
                      IF ( lv_cnvs_business_person_mst1 = lv_intro_business_person ) THEN
                        --エラー対象
                        lv_int_bus_per_flag2 := cv_yes;
                      END IF;
                    --
                    END IF;
                  --
                  ELSIF ( lv_cnvs_business_person_mst2 IS NOT NULL ) THEN
                  --CSVに獲得営業員が設定されている場合
                    --
                    --CSVに設定された獲得営業員とCSVに設定されている紹介営業員が同じ場合
                    IF ( lv_cnvs_business_person_mst2 = lv_intro_business_person ) THEN
                      --エラー対象
                      lv_int_bus_per_flag2 := cv_yes;
                    END IF;
                  --
                  END IF;
                  --
                  --DBに設定された獲得営業員とCSVに設定されている紹介営業員が同じ場合
                  --または、CSVに設定された獲得営業員とCSVに設定されている紹介営業員が同じ場合
                  IF ( lv_int_bus_per_flag2 = cv_yes ) THEN
                    lv_check_status   := cv_status_error;
                    lv_retcode        := cv_status_error;
                    --獲得営業員紹介者チェックエラーメッセージ取得
                    gv_out_msg := xxccp_common_pkg.get_msg(
                                     iv_application  => gv_xxcmm_msg_kbn
                                    ,iv_name         => cv_intro_person_err_msg
                                    ,iv_token_name1  => cv_cust_code
                                    ,iv_token_value1 => lv_customer_code
                                   );
                    FND_FILE.PUT_LINE(
                       which  => FND_FILE.LOG
                      ,buff   => gv_out_msg
                    );
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
        --顧客区分「13：法人顧客」の場合
        IF ( lv_cust_customer_class = cv_trust_corp ) THEN
        --
          --TDBコード取得
          lv_tdb_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
-- Ver1.10 mod start
--                                                                ,51);
-- Ver1.14 mod start
--                                                                ,76);
-- Ver1.16 mod start
--                                                                ,77);
-- Ver1.27 mod start
--                                                                ,79);
                                                                ,80);
-- Ver1.27 mod end
-- Ver1.16 mod end
-- Ver1.14 mod end
-- Ver1.10 mod end
          --CSVに設定されたTDBコードが任意の値の場合
          IF ( lv_tdb_code <> cv_null_bar ) THEN
            --TDBコードの型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_tdb_code         --項目名称
                                                ,lv_tdb_code         --TDBコード
                                                ,12                  --項目長
                                                ,NULL                --項目長（小数点以下）
                                                ,cv_null_ok          --必須フラグ
                                                ,cv_element_vc2      --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf      --エラーバッファ
                                                ,lv_item_retcode     --エラーコード
                                                ,lv_item_errmsg);    --エラーメッセージ
            --TDBコード型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --TDBコードエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_tdb_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_tdb_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg);
            END IF;
          --
          END IF;
        --
        END IF;
--
        --顧客区分「13：法人顧客」の場合
        IF ( lv_cust_customer_class = cv_trust_corp ) THEN
        --
          --決裁日付取得
          lv_corp_approval_date := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.10 mod start
--                                                                     ,52);
-- Ver1.14 mod start
--                                                                     ,80);
-- Ver1.16 mod start
--                                                                     ,81);
-- Ver1.21 mod start
--                                                                     ,83);
-- Ver1.27 mod start
--                                                                     ,84);
                                                                     ,85);
-- Ver1.27 mod end
-- Ver1.21 mod end
-- Ver1.16 mod end
-- Ver1.14 mod end
-- Ver1.10 mod end
--
          --CSVに設定された決裁日付取得が任意の値の場合
          IF ( lv_corp_approval_date <> cv_null_bar ) THEN
            --決裁日付の型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_approval_date    --項目名称
                                                ,lv_corp_approval_date  --決裁日付
                                                ,NULL                --項目長
                                                ,NULL                --項目長（小数点以下）
                                                ,cv_null_ok          --必須フラグ
                                                ,cv_element_dat      --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf      --エラーバッファ
                                                ,lv_item_retcode     --エラーコード
                                                ,lv_item_errmsg);    --エラーメッセージ
            --決裁日付型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --決裁日付エラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_approval_date
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_corp_approval_date
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg);
            END IF;
          --
          END IF;
        --
        END IF;
--
        --顧客区分「13：法人顧客」の場合
        IF ( lv_cust_customer_class = cv_trust_corp ) THEN
          --
          --本部担当拠点取得
          lv_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                 ,cv_comma
-- Ver1.10 mod start
--                                                                 ,53);
-- Ver1.14 mod start
--                                                                 ,77);
-- Ver1.16 mod start
--                                                                 ,78);
-- Ver1.27 mod start
--                                                                 ,80);
                                                                 ,81);
-- Ver1.27 mod end
-- Ver1.16 mod end
-- Ver1.14 mod end
-- Ver1.10 mod end
          --CSVに設定された本部担当拠点が任意の値の場合
          IF (lv_base_code <> cv_null_bar) THEN
            --本部担当拠点存在チェック
            << check_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_base_code )
            LOOP
              lv_base_code_mst := check_flex_value_rec.flex_value;
            END LOOP check_base_code_loop;
            IF (lv_base_code_mst IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --本部担当拠点参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          ELSIF (lv_base_code = cv_null_bar) THEN 
          --CSVに設定された本部担当拠点が'-'の場合
            lv_check_status    := cv_status_error;
            lv_retcode         := cv_status_error;
            --本部担当拠点必須エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_base_code_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_base_code
                            ,iv_token_name2  => cv_cust_code
                            ,iv_token_value2 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          --
          END IF;
        --
        END IF;
--
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
--
        -- 売上実績振替取得
        lv_selling_transfer_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                          ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                          ,42);
-- Ver1.10 mod start
--                                                                          ,54);
                                                                          ,27);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --売上実績振替型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_selling_transfer_div   --売上実績振替
                                            ,lv_selling_transfer_div   --売上実績振替
                                            ,1                         --項目長
                                            ,NULL                      --項目長（小数点以下）
                                            ,cv_null_ok                --必須フラグ
                                            ,cv_element_vc2            --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf            --エラーバッファ
                                            ,lv_item_retcode           --エラーコード
                                            ,lv_item_errmsg);          --エラーメッセージ
        --売上実績振替型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --売上実績振替エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_selling_transfer_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_selling_transfer_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
-- Ver1.10 add start
          --売上実績振替チェックフラグFALSE
          lb_sell_trans_chk_flg := FALSE;
-- Ver1.10 add end
        END IF;
        --売上実績振替が-でない場合
        -- 顧客区分'10','12','13','14','15','16','17'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          IF (lv_selling_transfer_div <> cv_null_bar) THEN
            --売上実績振替存在チェック
            << check_selling_transfer_loop >>
            FOR check_lookup_type_rec IN check_lookup_type_cur( lv_selling_transfer_div, cv_uriage_jisseki_furi )
            LOOP
              lv_selling_transfer_div_mst     := check_lookup_type_rec.lookup_code;
            END LOOP check_selling_transfer_loop;
            IF (lv_selling_transfer_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --売上実績振替存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_selling_transfer_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_selling_transfer_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
-- Ver1.10 add start
              --売上実績振替チェックフラグFALSE
              lb_sell_trans_chk_flg := FALSE;
-- Ver1.10 add end
            END IF;
          END IF;
        END IF;
-- Ver1.10 add start
        --売上実績振替の妥当性チェックOKの場合、更新値を取得
        IF (lb_sell_trans_chk_flg = TRUE)
        THEN
          -- チェック用に顧客追加情報の現在値を取得
          << get_xca_info_loop >>
          FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
          LOOP
            lt_sell_trans_div_bef := get_xca_info_rec.selling_transfer_div;
          END LOOP get_xca_info_loop;
          --
          --変更値が'-'の場合
          IF (lv_selling_transfer_div = cv_null_bar)
          THEN
            lt_sell_trans_div_aft := NULL;
          --変更値がNULLまたは、
          --顧客区分が'18','19','20','21'の場合
          ELSIF (lv_selling_transfer_div IS NULL)
            OR  (lv_cust_customer_class IN ( cv_edi_class
                                           , cv_hyakkaten_kbn
                                           , cv_seikyusho_kbn
                                           , cv_toukatu_kbn))
          THEN
            --更新前の値を設定
            lt_sell_trans_div_aft := lt_sell_trans_div_bef;
          ELSE
            --CSVの値を設定
            lt_sell_trans_div_aft := lv_selling_transfer_div;
          END IF;
        END IF;
-- Ver1.10 add end
        --
        -- カード会社取得
        lv_card_company := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                  ,43);
-- Ver1.10 mod start
--                                                                  ,55);
-- Ver1.27 mod start
--                                                                  ,62);
                                                                  ,63);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --カード会社型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_card_company   --カード会社
                                            ,lv_card_company   --カード会社
                                            ,9                 --項目長
                                            ,NULL              --項目長（小数点以下）
                                            ,cv_null_ok        --必須フラグ
                                            ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf    --エラーバッファ
                                            ,lv_item_retcode   --エラーコード
                                            ,lv_item_errmsg);  --エラーメッセージ
        --カード会社型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --カード会社エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_card_company
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_card_company
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- 顧客区分'10'の場合のみエラーチェックを行う
        IF (lv_cust_customer_class = cv_kokyaku_kbn) THEN
          --カード会社が-でない場合
          IF (lv_card_company <> cv_null_bar) THEN
            --カード会社存在チェック
            << check_card_company_loop >>
            FOR check_card_company_rec IN check_card_company_cur( lv_card_company )
            LOOP
              lv_card_company_mst     := check_card_company_rec.cust_id;
            END LOOP check_card_company_loop;
            IF (lv_card_company_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --カード会社マスタ存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_card_company
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_card_company
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_cust_acct_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --カード会社相関チェック
            --業態（小分類）が'24','25'以外が設定されている場合
            IF (lv_business_low_type NOT IN (cv_gyotai_full_syoka_vd, cv_gyotai_full_vd)) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --カード会社相関チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_set_item_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_card_company
                              ,iv_token_name2  => cv_cond_col_name
                              ,iv_token_value2 => cv_bus_low_type
                              ,iv_token_name3  => cv_cond_col_val
                              ,iv_token_value3 => lv_business_low_type
                              ,iv_token_name4  => cv_cust_code
                              ,iv_token_value4 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- 問屋管理コード取得
        lv_wholesale_ctrl_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                         ,44);
-- Ver1.10 mod start
--                                                                         ,56);
                                                                         ,29);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --問屋管理コード型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_wholesale_ctrl_code   --問屋管理コード
                                            ,lv_wholesale_ctrl_code   --問屋管理コード
                                            ,9                        --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --問屋管理コード型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --問屋管理コードエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_wholesale_ctrl_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_wholesale_ctrl_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- 顧客区分'10','12','13','14','15','16','17'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          --問屋管理コードが-でない場合
          IF (lv_wholesale_ctrl_code <> cv_null_bar) THEN
            --問屋管理コード存在チェック
            << check_wholesale_ctrl_code_loop >>
            FOR check_lookup_type_rec IN check_lookup_type_cur( lv_wholesale_ctrl_code, cv_tonya_code )
            LOOP
              lv_wholesale_ctrl_code_mst     := check_lookup_type_rec.lookup_code;
            END LOOP check_wholesale_ctrl_code_loop;
            IF (lv_wholesale_ctrl_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --問屋管理コード存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_wholesale_ctrl_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_wholesale_ctrl_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- 価格表取得
        lv_price_list := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                ,45);
-- Ver1.10 mod start
--                                                                ,57);
                                                                ,18);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- Ver1.26 add start
        -- 事務センター所属チェック
        -- ※事務センター以外の拠点に所属するユーザが、価格表を指定してアップロードした場合エラー
        IF ( lv_price_list IS NOT NULL ) THEN
--
          --========================================
          -- 所属拠点確認処理
          --========================================
          -- ユーザーの所属拠点が事務センターか確認します。
          BEGIN
            SELECT  COUNT(1)            AS base_code_business_cnt
            INTO    ln_base_code_business_cnt
            FROM    fnd_lookup_values flv
            WHERE   flv.lookup_type      = cv_base_code_business
            AND     flv.lookup_code      = gv_user_base_code
            AND     flv.enabled_flag     = cv_yes
            AND     flv.language         = cv_language_ja
            AND     gd_process_date BETWEEN flv.start_date_active 
                                     AND NVL(flv.end_date_active,gd_process_date)
            ;
          END;
--
          -- 事務センター所属チェックの判別
          IF (ln_base_code_business_cnt = 0) THEN
            lv_check_status   := cv_status_error;
            lv_retcode      := cv_status_error;
            -- エラーメッセージ作成
            gv_out_msg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,cv_msg_base_business_err);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
        END IF;
-- Ver1.26 add end
        --価格表型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_price_list    --価格表
                                            ,lv_price_list    --価格表
                                            ,240              --項目長
                                            ,NULL             --項目長（小数点以下）
                                            ,cv_null_ok       --必須フラグ
                                            ,cv_element_vc2   --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf   --エラーバッファ
                                            ,lv_item_retcode  --エラーコード
                                            ,lv_item_errmsg); --エラーメッセージ
        --価格表型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --価格表エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_price_list
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_price_list
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- 顧客区分'10','12'の場合、エラーチェックを行う
        IF (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn)) THEN
          --価格表が-でない場合
          IF (lv_price_list <> cv_null_bar) THEN
            --価格表存在チェック
            << check_price_list_loop >>
            FOR check_price_list_rec IN check_price_list_cur( lv_price_list )
            LOOP
              lv_price_list_mst     := check_price_list_rec.list_header_id;
            END LOOP check_price_list_loop;
            IF (lv_price_list_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --価格表マスタ存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_price_list
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_price_list
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_qp_list_headers_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--        -- 職責管理フラグが'Y'の場合
--        IF (gv_resp_flag = cv_yes) THEN
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
          -- 出荷元保管場所取得
          lv_ship_storage_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                         ,46);
-- Ver1.10 mod start
--                                                                         ,58);
                                                                         ,30);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
          --出荷元保管場所型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_ship_storage_code    --出荷元保管場所
                                              ,lv_ship_storage_code    --出荷元保管場所
                                              ,10                      --項目長
                                              ,NULL                    --項目長（小数点以下）
                                              ,cv_null_ok              --必須フラグ
                                              ,cv_element_vc2          --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf          --エラーバッファ
                                              ,lv_item_retcode         --エラーコード
                                              ,lv_item_errmsg);        --エラーメッセージ
          --出荷元保管場所型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --出荷元保管場所エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ship_storage_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ship_storage_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
-- Ver1.10 add start
            --出荷元保管場所チェックフラグFALSE
            lb_sp_strg_code_chk_flg := FALSE;
-- Ver1.10 add end
          END IF;
          -- 顧客区分'10','12','13','14','15','16','17'の場合、エラーチェックを行う
          IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
            --出荷元保管場所が-でない場合
            IF (lv_ship_storage_code <> cv_null_bar) THEN
              --出荷元保管場所存在チェック
              << check_ship_storage_code_loop >>
              FOR check_ship_storage_code_rec IN check_ship_storage_code_cur( lv_ship_storage_code )
              LOOP
                lv_ship_storage_code_mst  := check_ship_storage_code_rec.secondary_inventory_name;
              END LOOP check_price_list_loop;
              IF (lv_ship_storage_code_mst IS NULL) THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --出荷元保管場所マスタ存在チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_mst_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_ship_storage_code
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_ship_storage_code
                                ,iv_token_name4  => cv_table
                                ,iv_token_value4 => cv_second_inv_mst
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
-- Ver1.10 add start
                --出荷元保管場所チェックフラグFALSE
                lb_sp_strg_code_chk_flg := FALSE;
-- Ver1.10 add end
              END IF;
            END IF;
          END IF;
-- Ver1.10 add start
          --出荷元保管場所の妥当性チェックOKの場合、更新値を取得
          IF (lb_sp_strg_code_chk_flg = TRUE)
          THEN
            -- チェック用に顧客追加情報の現在値を取得
            << get_xca_info_loop >>
            FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
            LOOP
              lt_ship_storage_code_bef := get_xca_info_rec.ship_storage_code;
            END LOOP get_xca_info_loop;
            --
            --変更値が'-'の場合
            IF (lv_ship_storage_code = cv_null_bar)
            THEN
              lt_ship_storage_code_aft := NULL;
            --変更値がNULLまたは、
            --顧客区分が'18','19','20','21'の場合
            ELSIF (lv_ship_storage_code IS NULL)
              OR  (lv_cust_customer_class IN ( cv_edi_class
                                             , cv_hyakkaten_kbn
                                             , cv_seikyusho_kbn
                                             , cv_toukatu_kbn))
            THEN
              --更新前の値を設定
              lt_ship_storage_code_aft := lt_ship_storage_code_bef;
            ELSE
              --CSVの値を設定
              lt_ship_storage_code_aft := lv_ship_storage_code;
            END IF;
          END IF;
-- Ver1.10 add end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--        ELSE
--          -- 職責管理プロファイルが'N'の場合、出荷元保管場所にNULLをセット
--          lv_ship_storage_code := NULL;
--        END IF;
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
        -- ===========================================
        -- 配送順（EDI）の取得・チェック
        -- ===========================================
        -- 配送順（EDI） 取得
        lv_delivery_order := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                    ,48);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                    ,47);
-- Ver1.10 mod start
--                                                                    ,59);
-- Ver1.27 mod start
--                                                                    ,53);
                                                                    ,54);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --配送順（EDI） 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_delivery_order        --配送順（EDI）
                                            ,lv_delivery_order        --配送順（EDI）
                                            ,14                       --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --配送順（EDI） 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --配送順（EDI） エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_order
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_delivery_order
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- EDI地区コード（EDI）の取得・チェック
        -- ===========================================
        -- EDI地区コード（EDI） 取得
        lv_edi_district_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                       ,49);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                       ,48);
-- Ver1.10 mod start
--                                                                       ,60);
-- Ver1.27 mod start
--                                                                       ,54);
                                                                       ,55);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --EDI地区コード（EDI） 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_edi_district_code     --EDI地区コード（EDI）
                                            ,lv_edi_district_code     --EDI地区コード（EDI）
                                            ,8                        --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --EDI地区コード（EDI） 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI地区コード（EDI） エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --EDI地区コード（EDI）の半角文字チェック
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_edi_district_code), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --半角文字チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- EDI地区名（EDI）の取得・チェック
        -- ===========================================
        -- EDI地区名（EDI） 取得
        lv_edi_district_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                       ,50);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                       ,49);
-- Ver1.10 mod start
--                                                                       ,61);
-- Ver1.27 mod start
--                                                                       ,55);
                                                                       ,56);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --EDI地区名（EDI） 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_edi_district_name     --EDI地区名（EDI）
                                            ,lv_edi_district_name     --EDI地区名（EDI）
                                            ,40                       --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --EDI地区名（EDI） 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI地区名（EDI） エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- 全角文字チェック（ただし'-'は除く）
        IF (NVL(xxccp_common_pkg.chk_double_byte(lv_edi_district_name), TRUE) = FALSE)
          AND (lv_edi_district_name <> cv_null_bar)
        THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --全角文字チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_double_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- EDI地区名カナ（EDI）の取得・チェック
        -- ===========================================
        -- EDI地区名カナ（EDI） 取得
        lv_edi_district_kana := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                       ,51);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                       ,50);
-- Ver1.10 mod start
--                                                                       ,62);
-- Ver1.27 mod start
--                                                                       ,56);
                                                                       ,57);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --EDI地区名カナ（EDI） 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_edi_district_kana     --EDI地区名カナ（EDI）
                                            ,lv_edi_district_kana     --EDI地区名カナ（EDI）
                                            ,20                       --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --EDI地区名カナ（EDI） 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI地区名カナ（EDI） エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --半角文字チェック
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_edi_district_kana), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --半角文字チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- 通過在庫型区分（EDI）の取得・チェック
        -- ===========================================
        -- 通過在庫型区分（EDI） 取得
        lv_tsukagatazaiko_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                        ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                        ,52);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                        ,51);
-- Ver1.10 mod start
--                                                                        ,63);
-- Ver1.27 mod start
--                                                                        ,57);
                                                                        ,58);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --通過在庫型区分（EDI） 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_tsukagatazaiko_div    --通過在庫型区分（EDI）
                                            ,lv_tsukagatazaiko_div    --通過在庫型区分（EDI）
                                            ,2                        --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --通過在庫型区分（EDI） 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --通過在庫型区分（EDI） エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_tsukagatazaiko_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_tsukagatazaiko_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
-- Ver1.10 add start
          --通過在庫型区分チェックフラグFALSE
          lb_tsukazaiko_chk_flg := FALSE;
-- Ver1.10 add end
        END IF;
--
        --通過在庫型区分（EDI）に'-'以外の値が入っている場合
        IF (NVL(lv_tsukagatazaiko_div , cv_null_bar) <> cv_null_bar) THEN
          --参照タイプ 通過在庫型区分（EDI）存在チェック
          << check_tsukagatazaiko_div_loop >>
          FOR check_lookup_type_rec IN check_lookup_type_cur( lv_tsukagatazaiko_div , cv_tsukagatazaiko_kbn )
          LOOP
            lv_tsukagatazaiko_div_mst  := check_lookup_type_rec.lookup_code;
          END LOOP check_tsukagatazaiko_div_loop;
          IF (lv_tsukagatazaiko_div_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --通過在庫型区分（EDI）存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_tsukagatazaiko_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_tsukagatazaiko_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
-- Ver1.10 add start
            --通過在庫型区分チェックフラグFALSE
            lb_tsukazaiko_chk_flg := FALSE;
-- Ver1.10 add end
          END IF;
--
          --通過在庫型区分（EDI） を入力する場合、チェーン店コード(EDI)の入力必須
          --CSVに設定されたチェーン店コード(EDI)が'-'の場合
          IF (lv_edi_chain_code = cv_null_bar) THEN
            --エラー対象
            lv_tsukagatazaiko_flag := cv_yes;
          --
          --CSVに設定されたチェーン店コード(EDI)がNULLの場合
          ELSIF (lv_edi_chain_code IS NULL) THEN
            --顧客追加情報のチェーン店コード(EDI)存在チェック
            << check_db_chain_store_loop >>
            FOR check_db_customer_rec IN check_db_customer_cur( lv_customer_code )
            LOOP
              lv_chain_store_db  := check_db_customer_rec.chain_store_code;
            END LOOP check_db_chain_store_loop;
            --顧客追加情報のチェーン店コード(EDI)が'Y'の場合
            IF (lv_chain_store_db IS NULL) THEN
              --エラー対象
              lv_tsukagatazaiko_flag := cv_yes;
            END IF;
          END IF;
--
        END IF;
--
        --通過在庫型区分（EDI） を入力する場合、チェーン店コード(EDI)の入力必須
        --通過在庫型区分（EDI）がNULL の場合
        IF (lv_tsukagatazaiko_div IS NULL) THEN
          --顧客追加情報の通過在庫型区分（EDI）存在チェック
          << check_db_tsukagatazaiko_loop >>
          FOR check_db_customer_rec IN check_db_customer_cur( lv_customer_code )
          LOOP
            lv_tsukagatazaiko_div_db  := check_db_customer_rec.tsukagatazaiko_div;
          END LOOP check_db_tsukagatazaiko_loop;
          --顧客追加情報の通過在庫型区分（EDI）がNULLでない
          --かつ、チェーン店コード(EDI)が'-' の場合
          IF (lv_tsukagatazaiko_div_db IS NOT NULL)
            AND (lv_edi_chain_code = cv_null_bar)
          THEN
            --エラー対象
            lv_tsukagatazaiko_flag := cv_yes;
          END IF;
        END IF;
--
-- Ver1.18 add start
        --上記以外のチェックの為、顧客追加情報のチェーン店コード、顧客追加情報の通過在庫型区分（EDI）を取得しなおす
        lv_chain_store_db                        := NULL;
        lv_tsukagatazaiko_div_db                 := NULL;
        check_db_customer_rec.chain_store_code   := NULL;
        check_db_customer_rec.tsukagatazaiko_div := NULL;
--
        << check_db_edi_loop >>
        FOR check_db_customer_rec IN check_db_customer_cur( lv_customer_code )
        LOOP
          lv_chain_store_db         := check_db_customer_rec.chain_store_code;
          lv_tsukagatazaiko_div_db  := check_db_customer_rec.tsukagatazaiko_div;
        END LOOP check_db_edi_loop;
--
        --通過在庫型区分（EDI）が'-'
        --かつ、チェーン店コード(EDI)がNULL、もしくは、'-'でない場合
        IF ( lv_tsukagatazaiko_div = cv_null_bar )
          AND ( NVL( lv_edi_chain_code, cv_null_bar ) <> cv_null_bar )
        THEN
          --エラー対象
          lv_tsukagatazaiko_flag := cv_yes;
        END IF;
--
        --顧客追加情報のチェーン店コード(EDI)ありの場合
        IF ( lv_chain_store_db IS NOT NULL ) THEN
--
          --通過在庫型区分（EDI）が'-'
          --かつ、チェーン店コード(EDI)がNULLの場合
          IF ( lv_tsukagatazaiko_div = cv_null_bar )
            AND ( lv_edi_chain_code IS NULL )
          THEN
            --エラー対象
            lv_tsukagatazaiko_flag := cv_yes;
          END IF;
--
          --顧客追加情報の通過在庫型区分（EDI）がない場合
          IF ( lv_tsukagatazaiko_div_db IS NULL ) THEN
            --チェーン店コード(EDI)がNULL、もしくは'-'以外
            --かつ、通過在庫型区分（EDI）がNULLの場合
            IF ( NVL( lv_edi_chain_code, cv_null_bar ) <> cv_null_bar )
              AND ( lv_tsukagatazaiko_div IS NULL )
            THEN
              --エラー対象
              lv_tsukagatazaiko_flag := cv_yes;
            END IF;
            --チェーン店コード(EDI)がNULL
            --かつ、通過在庫型区分（EDI）がNULLの場合
            IF ( lv_edi_chain_code IS NULL )
              AND ( lv_tsukagatazaiko_div IS NULL )
            THEN
              --エラー対象
              lv_tsukagatazaiko_flag := cv_yes;
            END IF;
          END IF;
--
        --顧客追加情報のチェーン店コード(EDI)なしの場合
        ELSE
--
          --顧客追加情報の通過在庫型区分（EDI）があり場合
          IF ( lv_tsukagatazaiko_div_db IS NOT NULL ) THEN
            --チェーン店コード(EDI)がNULL、もしくは、'-'
            --かつ、通過在庫型区分（EDI）がNULLの場合
            IF ( NVL( lv_edi_chain_code, cv_null_bar ) = cv_null_bar )
              AND ( lv_tsukagatazaiko_div IS NULL )
            THEN
              --エラー対象
              lv_tsukagatazaiko_flag := cv_yes;
            END IF;
          --顧客追加情報の通過在庫型区分（EDI）がなしの場合
          ELSE
            --チェーン店コード(EDI)がNULL、もしくは、'-'以外
            --かつ、通過在庫型区分（EDI）がNULLの場合、
            IF ( NVL( lv_edi_chain_code, cv_null_bar ) <> cv_null_bar )
              AND ( lv_tsukagatazaiko_div IS NULL )
            THEN
              --エラー対象
              lv_tsukagatazaiko_flag := cv_yes;
            END IF;
          END IF;
--
        END IF;
-- Ver1.18 add end
--
        --上記でエラー対象となった場合、項目設定チェックエラー
        IF (lv_tsukagatazaiko_flag = cv_yes) THEN
          --エラーメッセージの設定
          lv_check_status   := cv_status_error;
          lv_retcode        := cv_status_error;
          --通過在庫型区分（EDI）存在チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_chain_tsukazaiko_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
-- Ver1.10 add start
          --通過在庫型区分チェックフラグFALSE
          lb_tsukazaiko_chk_flg := FALSE;
-- Ver1.10 add end
        END IF;
-- Ver1.10 add start
        --通過在庫型区分の妥当性チェックOKの場合、更新値を取得
        IF (lb_tsukazaiko_chk_flg = TRUE)
        THEN
          -- チェック用に顧客追加情報の現在値を取得
          << get_xca_info_loop >>
          FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
          LOOP
            lt_tsukagatazaiko_div_bef  := get_xca_info_rec.tsukagatazaiko_div;
          END LOOP get_xca_info_loop;
          --
          --変更値が'-'の場合
          IF (lv_tsukagatazaiko_div = cv_null_bar)
          THEN
            lt_tsukagatazaiko_div_aft := NULL;
          --変更値がNULLの場合
          ELSIF (lv_tsukagatazaiko_div IS NULL)
          THEN
            --更新前の値を設定
            lt_tsukagatazaiko_div_aft := lt_tsukagatazaiko_div_bef;
          ELSE
            --CSVの値を設定
            lt_tsukagatazaiko_div_aft := lv_tsukagatazaiko_div;
          END IF;
--
          --職責管理フラグが'N'の場合のみチェック
          IF (gv_resp_flag = cv_no)
          THEN
            -- ===========================================
            -- 納品拠点の相関チェック
            -- ===========================================
            --通過在庫型区分、売上実績振替、納品拠点の妥当性チェックOKの場合
            IF    (lb_sell_trans_chk_flg = TRUE)
              AND (lb_db_code_chk_flg    = TRUE)
            THEN
              --顧客区分が'14'かつ、
              --売上実績振替が'1'または、通過在庫型区分が'24'以外の場合、入力必須
              IF     (lv_cust_customer_class = cv_urikake_kbn)
                AND (
                     (NVL(lt_sell_trans_div_aft ,cv_dummy_0) = cv_in_transfer)
                 OR  (NVL(lt_tsukagatazaiko_div_aft ,cv_center_no_stock) <> cv_center_no_stock)
                    )
                AND (lt_delivery_base_code_aft IS NULL)
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --納品拠点相関チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_deliv_rel_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
              END IF;
            END IF;
--
            -- ===========================================
            -- 出荷元保管場所の相関チェック
            -- ===========================================
            --通過在庫型区分およびチェーン店(EDI)の妥当性チェックOKの場合
            IF    (lb_sp_strg_code_chk_flg = TRUE)
              AND (lb_cs_code_chk_flg      = TRUE)
            THEN
              ---------------------------------
              --出荷元保管場所の相関チェック１
              ---------------------------------
              --顧客区分が'10'かつ、チェーン店(EDI)または、通過在庫型区分に値が入力されている場合、入力必須
              IF     (lv_cust_customer_class = cv_kokyaku_kbn)
                AND (
                     (lt_chain_store_code_aft   IS NOT NULL)  --チェーン店(EDI)
                  OR (lt_tsukagatazaiko_div_aft IS NOT NULL)  --通過在庫型区分
                    )
                AND  (lt_ship_storage_code_aft  IS NULL)
              THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --出荷元保管場所相関チェック１メッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_ss_code_rel_err1_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
              END IF;
--
              ---------------------------------
              --出荷元保管場所の相関チェック２
              ---------------------------------
              --顧客区分が'10'かつ、通過在庫型区分が'12','13'かつ、チェーン店コード(EDI)に値が入力されている場合
              IF    (lv_cust_customer_class = cv_kokyaku_kbn)
                AND (NVL(lt_tsukagatazaiko_div_aft ,cv_dummy_0) IN (cv_center_stock_order
                                                                   ,cv_center_stock_delivery))
                AND (lt_chain_store_code_aft IS NOT NULL)
              THEN
                << check_ss_code_rel_loop >>
-- Ver1.11 mod start
--                FOR check_ss_code_rel_rec IN check_ss_code_rel_cur(lt_chain_store_code_aft    --チェーン店コード(EDI)
--                                                                  ,lt_ship_storage_code_aft)  --出荷元保管場所
                FOR check_ss_code_rel_rec IN check_ss_code_rel_cur(lt_ship_storage_code_aft    --出荷元保管場所
                                                                  ,lt_chain_store_code_aft)    --チェーン店コード(EDI)
-- Ver1.11 mod end
                LOOP
                  lt_chain_store_code_mst  := check_ss_code_rel_rec.chain_store_code;
                END LOOP check_ss_code_rel_loop;
                --
                IF (lt_chain_store_code_mst IS NULL)
                THEN
                  lv_check_status   := cv_status_error;
                  lv_retcode        := cv_status_error;
                  --出荷元保管場所相関チェック２メッセージ取得
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => gv_xxcmm_msg_kbn
                                  ,iv_name         => cv_ss_code_rel_err2_msg
                                  ,iv_token_name1  => cv_cust_code
                                  ,iv_token_value1 => lv_customer_code
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.LOG
                    ,buff   => gv_out_msg);
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
-- Ver1.10 add end
--
        -- ===========================================
        -- EDI納品センターコードの取得・チェック
        -- ===========================================
        -- EDI納品センターコード 取得
        lv_deli_center_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                      ,53);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                      ,52);
-- Ver1.10 mod start
--                                                                      ,64);
-- Ver1.27 mod start
--                                                                      ,58);
                                                                      ,59);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --EDI納品センターコード 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_deli_center_code      --EDI納品センターコード
                                            ,lv_deli_center_code      --EDI納品センターコード
                                            ,8                        --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --EDI納品センターコード 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI納品センターコード エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_deli_center_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_deli_center_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- EDI納品センター名の取得・チェック
        -- ===========================================
        -- EDI納品センター名 取得
        lv_deli_center_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                      ,54);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                      ,53);
-- Ver1.10 mod start
--                                                                      ,65);
-- Ver1.27 mod start
--                                                                      ,59);
                                                                      ,60);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --EDI納品センター名 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_deli_center_name      --EDI納品センター名
                                            ,lv_deli_center_name      --EDI納品センター名
                                            ,20                       --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --EDI納品センター名 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI納品センター名 エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_deli_center_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_deli_center_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- EDI伝送追番の取得・チェック
        -- ===========================================
        -- EDI伝送追番 取得
        lv_edi_forward_number := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                        ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                        ,55);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                        ,54);
-- Ver1.10 mod start
--                                                                        ,66);
-- Ver1.27 mod start
--                                                                        ,60);
                                                                        ,61);
-- Ver1.27 mod end
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --EDI伝送追番 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_edi_forward_number    --EDI伝送追番
                                            ,lv_edi_forward_number    --EDI伝送追番
                                            ,2                        --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --EDI伝送追番 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI伝送追番 エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_forward_number
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_forward_number
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- 顧客店舗名称の取得・チェック
        -- ===========================================
        -- 顧客店舗名称 取得
        lv_cust_store_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                     ,56);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                     ,55);
-- Ver1.10 mod start
--                                                                     ,67);
                                                                     ,42);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --顧客店舗名称 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_cust_store_name       --顧客店舗名称
                                            ,lv_cust_store_name       --顧客店舗名称
                                            ,30                       --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --顧客店舗名称 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --顧客店舗名称 エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_store_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_store_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- 全角文字チェック（ただし'-'は除く）
        IF (NVL(xxccp_common_pkg.chk_double_byte(lv_cust_store_name), TRUE) = FALSE)
          AND (lv_cust_store_name <> cv_null_bar)
        THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --全角文字チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_double_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_store_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_store_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- 取引先コードの取得・チェック
        -- ===========================================
        -- 取引先コード 取得
        lv_torihikisaki_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod start by S.Niki
--                                                                       ,57);
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                       ,56);
-- Ver1.10 mod start
--                                                                       ,68);
                                                                       ,43);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_本稼動_09272 mod end by S.Niki
        --取引先コード 型・桁数チェック
        xxccp_common_pkg2.upload_item_check( cv_torihikisaki_code     --取引先コード
                                            ,lv_torihikisaki_code     --取引先コード
                                            ,8                        --項目長
                                            ,NULL                     --項目長（小数点以下）
                                            ,cv_null_ok               --必須フラグ
                                            ,cv_element_vc2           --属性（0・検証なし、1、数値、2、日付）
                                            ,lv_item_errbuf           --エラーバッファ
                                            ,lv_item_retcode          --エラーコード
                                            ,lv_item_errmsg);         --エラーメッセージ
        --取引先コード 型・桁数チェックエラー時
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --取引先コード エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_torihikisaki_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_torihikisaki_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --取引先コードの半角文字チェック
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_torihikisaki_code), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --半角文字チェックエラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_torihikisaki_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_torihikisaki_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
        -- ===========================================
        -- 訪問対象区分の取得・チェック
        -- ===========================================
        --訪問対象区分取得
        lv_vist_target_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod start by T.Nakano
--                                                                     ,57);
-- Ver1.10 mod start
--                                                                     ,69);
                                                                     ,33);
-- Ver1.10 mod end
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 mod end by T.Nakano
        --訪問対象区分が-でない場合
        IF (lv_vist_target_div <> cv_null_bar) THEN
          --訪問対象区分存在チェック
          << check_homon_taisyo_kbn_loop >>
          FOR check_homon_taisyo_kbn_rec IN check_homon_taisyo_kbn_cur( lv_vist_target_div )
          LOOP
            lv_vist_target_div_mst := check_homon_taisyo_kbn_rec.homon_taisyo_kbn;
          END LOOP check_homon_taisyo_kbn_loop;
          IF (lv_vist_target_div_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --訪問対象区分チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_vist_target_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_vist_target_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
--
          --訪問対象区分型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_vist_target_div     --訪問対象区分
                                              ,lv_vist_target_div     --訪問対象区分
                                              ,1                      --項目長
                                              ,NULL                   --項目長（小数点以下）
                                              ,cv_null_ok             --必須フラグ
                                              ,cv_element_vc2         --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf         --エラーバッファ
                                              ,lv_item_retcode        --エラーコード
                                              ,lv_item_errmsg);       --エラーメッセージ
          --訪問対象区分型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --訪問対象区分エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_vist_target_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_vist_target_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- Ver1.10 add start
        -- ===========================================
        -- 電話番号の取得・チェック
        -- ===========================================
        --電話番号取得
        lv_address_lines_phonetic := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                            ,cv_comma
                                                                            ,13);
        --必須項目チェック
        IF (lv_address_lines_phonetic = cv_null_bar)
        THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --必須項目エラーメッセージ取得
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address_lines_phonetic
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        --
        ELSIF (lv_address_lines_phonetic IS NOT NULL)
        THEN
          --型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_address_lines_phonetic       --電話番号
                                              ,lv_address_lines_phonetic       --電話番号
                                              ,30                --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ng        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --型・桁数エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address_lines_phonetic
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address_lines_phonetic
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
--
          --電話番号チェック
          IF (xxccp_common_pkg.chk_tel_format(lv_address_lines_phonetic) = FALSE)
          THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --電話番号チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_tel_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address_lines_phonetic
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address_lines_phonetic
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
        END IF;
--
        -- ===========================================
        -- FAXの取得・チェック
        -- ===========================================
        --FAX取得
        lv_address4 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
                                                              ,14);
        --NULL以外かつ、'-'でない場合
        IF (NVL(lv_address4 ,cv_null_bar) <> cv_null_bar)
        THEN
          --型・桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_address4       --FAX
                                              ,lv_address4       --FAX
                                              ,30                --項目長
                                              ,NULL              --項目長（小数点以下）
                                              ,cv_null_ok        --必須フラグ
                                              ,cv_element_vc2    --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf    --エラーバッファ
                                              ,lv_item_retcode   --エラーコード
                                              ,lv_item_errmsg);  --エラーメッセージ
          --型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --型・桁数エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address4
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address4
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
--
          --電話番号チェック
          IF (xxccp_common_pkg.chk_tel_format(lv_address4) = FALSE)
          THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --電話番号チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_tel_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address4
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address4
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
        END IF;
--
        -- ===========================================
        -- 消費税区分の取得・チェック
        -- ===========================================
        --顧客区分'10'、'12'、'14'の場合のみ取得・チェック
        IF (lv_cust_customer_class IN ( cv_kokyaku_kbn
                                      , cv_uesama_kbn
                                      , cv_urikake_kbn ) )
        THEN
          --消費税区分取得
          lv_tax_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                               ,cv_comma
                                                               ,28);
          --相関チェック
          IF (lv_tax_div = cv_null_bar)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_tax_div
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_tax_div IS NOT NULL)
          THEN
            --参照表存在チェック(使用可能='Y')
            << check_tax_div_loop >>
            FOR check_lookup_type_rec2 IN check_lookup_type_cur2( lv_tax_div
                                                                , cv_syohizei_kbn )
            LOOP
              lt_tax_div_aft := check_lookup_type_rec2.lookup_code;
            END LOOP check_tax_div_loop;
            --
            IF (lt_tax_div_aft IS NULL)
            THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_tax_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_tax_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
--
        -- ===========================================
        -- 売上拠点の取得・チェック
        -- ===========================================
        --顧客区分が'13'、'14'、'16'、'17'の場合のみ取得・チェック
        IF ( lv_cust_customer_class IN ( cv_trust_corp
                                       , cv_urikake_kbn
                                       , cv_tonya_kbn
                                       , cv_keikaku_kbn ) )
        THEN
          --売上拠点取得
          lv_sale_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
                                                                      ,34);
          --相関チェック
          IF (lv_sale_base_code = cv_null_bar)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --相関チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_sale_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_sale_base_code IS NOT NULL)
          THEN
            --値セット存在チェック
            << check_sale_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_sale_base_code )
            LOOP
              lt_sale_base_code_aft := check_flex_value_rec.flex_value;
            END LOOP check_sale_base_code_loop;
            --
            IF (lt_sale_base_code_aft IS NULL)
            THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --値セット存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_sale_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_sale_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          END IF;
        END IF;
--
        -- ===========================================
        --以降の項目は、顧客区分が'10'の場合のみ取得・チェック
        -- ===========================================
        IF (lv_cust_customer_class = cv_kokyaku_kbn )
        THEN
          -- チェック用に顧客追加情報の現在値を取得
          << get_xca_info_loop >>
          FOR get_xca_info_rec IN get_xca_info_cur( lv_customer_code )
          LOOP
            lt_longitude_bef          := get_xca_info_rec.longitude;         --ピークカット開始時刻
            lt_rate_bef               := get_xca_info_rec.rate;              --消化計算用掛率
            lt_conclusion_day1_bef    := get_xca_info_rec.conclusion_day1;   --消化計算締め日1
            lt_conclusion_day2_bef    := get_xca_info_rec.conclusion_day2;   --消化計算締め日2
            lt_conclusion_day3_bef    := get_xca_info_rec.conclusion_day3;   --消化計算締め日3
-- Ver1.16 add start
            lt_offset_cust_div        := get_xca_info_rec.offset_cust_div;   --相殺用顧客区分
            lt_offset_cust_code_bef   := get_xca_info_rec.offset_cust_code;  --相殺用顧客コード
            lt_bp_customer_code_bef   := get_xca_info_rec.bp_customer_code;  --取引先顧客コード
-- Ver1.16 add end
-- Ver1.19 add start
            lt_latitude_bef           := get_xca_info_rec.latitude;          --カテゴリー商品計上区分
-- Ver1.19 add end
          END LOOP get_xca_info_loop;
--
          --業態(小分類)の妥当性チェックOKの場合のみ取得・チェック
          IF (lb_bz_low_type_chk_flg = TRUE)
          THEN
            -- ===========================================
            -- ピークカット開始時刻の取得・チェック
            -- ===========================================
            --ピークカット開始時刻取得
            lv_longitude := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
-- Ver1.27 mod start
--                                                                   ,61);
                                                                   ,62);
-- Ver1.27 mod end
            --業態(小分類)が'24'、'25'、'27'の場合、入力必須
            IF     (lt_business_low_type_aft IN ( cv_gyotai_full_syoka_vd
                                                , cv_gyotai_full_vd
                                                , cv_gyotai_syoka_vd ) )
              AND ((lv_longitude = cv_null_bar)
               OR  (NVL(lv_longitude ,lt_longitude_bef) IS NULL))
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --相関チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_correlation_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_longitude
                              ,iv_token_name2  => cv_cond_col_name
                              ,iv_token_value2 => cv_bus_low_type
                              ,iv_token_name3  => cv_cond_col_val
                              ,iv_token_value3 => lt_business_low_type_aft
                              ,iv_token_name4  => cv_cust_code
                              ,iv_token_value4 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --NULL以外かつ、'-'でない場合
            ELSIF (NVL(lv_longitude, cv_null_bar) <> cv_null_bar)
            THEN
              --参照表存在チェック(使用可能='Y')
              << check_longitude_loop >>
              FOR check_lookup_type_rec2 IN check_lookup_type_cur2( lv_longitude
                                                                  , cv_peekcut_start_time )
              LOOP
                lt_longitude_aft := check_lookup_type_rec2.lookup_code;
              END LOOP check_longitude_loop;
              --
              IF (lt_longitude_aft IS NULL)
              THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --参照表存在チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_lookup_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_longitude
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_longitude
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
              END IF;
            END IF;
--
            -- ===========================================
            -- 稼働日カレンダの取得・チェック
            -- ===========================================
            --業態(小分類)が'24'、'25'、'27'の場合のみ取得・チェック
            IF (lt_business_low_type_aft IN ( cv_gyotai_full_syoka_vd
                                            , cv_gyotai_full_vd
                                            , cv_gyotai_syoka_vd ))
            THEN
              --稼働日カレンダ取得
              lv_calendar_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- Ver1.27 mod start
--                                                                         ,63);
                                                                         ,64);
-- Ver1.27 mod end
              --NULL以外かつ、'-'でない場合
              IF (NVL(lv_calendar_code ,cv_null_bar) <> cv_null_bar)
              THEN
                --マスタ存在チェック
                << check_calendar_code_loop >>
                FOR check_calendar_code_rec IN check_calendar_code_cur( lv_calendar_code )
                LOOP
                  lt_calendar_code_aft := check_calendar_code_rec.calendar_code;
                END LOOP check_calendar_code_loop;
                --
                IF (lt_calendar_code_aft IS NULL)
                THEN
                  lv_check_status    := cv_status_error;
                  lv_retcode         := cv_status_error;
                  --マスタ存在チェックエラーメッセージ取得
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => gv_xxcmm_msg_kbn
                                  ,iv_name         => cv_mst_err_msg
                                  ,iv_token_name1  => cv_cust_code
                                  ,iv_token_value1 => lv_customer_code
                                  ,iv_token_name2  => cv_col_name
                                  ,iv_token_value2 => cv_bom_calendars
                                  ,iv_token_name3  => cv_input_val
                                  ,iv_token_value3 => lv_calendar_code
                                  ,iv_token_name4  => cv_table
                                  ,iv_token_value4 => cv_bom_calendars_table
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.LOG
                    ,buff   => gv_out_msg
                  );
                END IF;
              END IF;
            END IF;
--
            -- ===========================================
            -- 消化計算用掛率の取得・チェック
            -- ===========================================
            --消化計算用掛率取得
            lv_rate := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- Ver1.27 mod start
--                                                              ,70);
                                                              ,71);
-- Ver1.27 mod end
            --業態(小分類)が'21'、'22'、'27'の場合、入力必須
            IF    (lt_business_low_type_aft IN ( cv_gyotai_inshop
                                               , cv_gyotai_tosya_tyokuei
                                               , cv_gyotai_syoka_vd ) )
              AND ((lv_rate = cv_null_bar)
               OR  (NVL(lv_rate ,lt_rate_bef) IS NULL))
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --相関チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_correlation_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_rate
                              ,iv_token_name2  => cv_cond_col_name
                              ,iv_token_value2 => cv_bus_low_type
                              ,iv_token_name3  => cv_cond_col_val
                              ,iv_token_value3 => lt_business_low_type_aft
                              ,iv_token_name4  => cv_cust_code
                              ,iv_token_value4 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --NULL以外かつ、'-'でない場合
            ELSIF (NVL(lv_rate ,cv_null_bar) <> cv_null_bar)
            THEN
              --型・桁数チェック
              xxccp_common_pkg2.upload_item_check( cv_rate           --消化計算用掛率
                                                  ,lv_rate           --消化計算用掛率
                                                  ,3                 --項目長
                                                  ,0                 --項目長（小数点以下）
                                                  ,cv_null_ok        --必須フラグ
                                                  ,cv_element_num    --属性（0・検証なし、1、数値、2、日付）
                                                  ,lv_item_errbuf    --エラーバッファ
                                                  ,lv_item_retcode   --エラーコード
                                                  ,lv_item_errmsg);  --エラーメッセージ
              --型・桁数チェックエラー時
              IF (lv_item_retcode <> cv_status_normal)
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --型・桁数エラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_val_form_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_rate
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_rate
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_item_errmsg
                );
              ELSE
                --範囲チェック
                IF  ( (TO_NUMBER(lv_rate) < cn_rate_min)
                  OR  (TO_NUMBER(lv_rate) > cn_rate_max) )
                THEN
                  lv_check_status := cv_status_error;
                  lv_retcode      := cv_status_error;
                  --範囲チェックエラーメッセージ取得
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => gv_xxcmm_msg_kbn
                                  ,iv_name         => cv_range_err_msg
                                  ,iv_token_name1  => cv_cust_code
                                  ,iv_token_value1 => lv_customer_code
                                  ,iv_token_name2  => cv_col_name
                                  ,iv_token_value2 => cv_rate
                                  ,iv_token_name3  => cv_input_val
                                  ,iv_token_value3 => lv_rate
                                  ,iv_token_name4  => cv_token_min_value
                                  ,iv_token_value4 => cn_rate_min
                                  ,iv_token_name5  => cv_token_max_value
                                  ,iv_token_value5 => cn_rate_max
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.LOG
                    ,buff   => gv_out_msg
                  );
                END IF;
              END IF;
            END IF;
          END IF;
--
          -- ===========================================
          -- 入金値引率の取得・チェック
          -- ===========================================
          --入金値引率取得
          lv_rcv_dsct_rate := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- Ver1.27 mod start
--                                                                     ,71);
                                                                     ,72);
-- Ver1.27 mod end
          --NULL以外かつ、'-'でない場合
          IF (NVL(lv_rcv_dsct_rate ,cv_null_bar) <> cv_null_bar)
          THEN
            --型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_rcv_dsct_rate  --入金値引率
                                                ,lv_rcv_dsct_rate  --入金値引率
                                                ,3                 --項目長
                                                ,1                 --項目長（小数点以下）
                                                ,cv_null_ok        --必須フラグ
                                                ,cv_element_num    --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf    --エラーバッファ
                                                ,lv_item_retcode   --エラーコード
                                                ,lv_item_errmsg);  --エラーメッセージ
            --型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --型・桁数チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_rcv_dsct_rate
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_rcv_dsct_rate
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --範囲チェック
              IF  ( (TO_NUMBER(lv_rcv_dsct_rate) < cn_rcv_dsct_rate_min)
                OR  (TO_NUMBER(lv_rcv_dsct_rate) > cn_rcv_dsct_rate_max) )
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --範囲チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_range_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_rcv_dsct_rate
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_rcv_dsct_rate
                                ,iv_token_name4  => cv_token_min_value
                                ,iv_token_value4 => cn_rcv_dsct_rate_min
                                ,iv_token_name5  => cv_token_max_value
                                ,iv_token_value5 => cn_rcv_dsct_rate_max
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
--
          -- ===========================================
          -- 消化計算締め日1の取得・チェック
          -- ===========================================
          --消化計算締め日1取得
          lv_conclusion_day1 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.27 mod start
--                                                                       ,72);
                                                                       ,73);
-- Ver1.27 mod end
          --NULL以外かつ、'-'でない場合
          IF (NVL(lv_conclusion_day1 ,cv_null_bar) <> cv_null_bar)
          THEN
            --型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_conclusion_day1   --消化計算締め日1
                                                ,lv_conclusion_day1   --消化計算締め日1
                                                ,2                    --項目長
                                                ,0                    --項目長（小数点以下）
                                                ,cv_null_ok           --必須フラグ
                                                ,cv_element_num       --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf       --エラーバッファ
                                                ,lv_item_retcode      --エラーコード
                                                ,lv_item_errmsg);     --エラーメッセージ
            --型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --型・桁数チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_conclusion_day1
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_conclusion_day1
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
              --消化計算締め日チェックフラグFALSE
              lb_conc_day_chk_flg := FALSE;
            ELSE
              --範囲チェック
              IF  ( (TO_NUMBER(lv_conclusion_day1) < cn_conc_day_min)
                OR  (TO_NUMBER(lv_conclusion_day1) > cn_conc_day_max) )
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --範囲チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_range_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_conclusion_day1
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_conclusion_day1
                                ,iv_token_name4  => cv_token_min_value
                                ,iv_token_value4 => cn_conc_day_min
                                ,iv_token_name5  => cv_token_max_value
                                ,iv_token_value5 => cn_conc_day_max
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
                --消化計算締め日チェックフラグFALSE
                lb_conc_day_chk_flg := FALSE;
              END IF;
            END IF;
          END IF;
--
          -- ===========================================
          -- 消化計算締め日2の取得・チェック
          -- ===========================================
          --消化計算締め日2取得
          lv_conclusion_day2 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.27 mod start
--                                                                       ,73);
                                                                       ,74);
-- Ver1.27 mod end
          --NULL以外かつ、'-'でない場合
          IF (NVL(lv_conclusion_day2 ,cv_null_bar) <> cv_null_bar)
          THEN
            --型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_conclusion_day2   --消化計算締め日2
                                                ,lv_conclusion_day2   --消化計算締め日2
                                                ,2                    --項目長
                                                ,0                    --項目長（小数点以下）
                                                ,cv_null_ok           --必須フラグ
                                                ,cv_element_num       --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf       --エラーバッファ
                                                ,lv_item_retcode      --エラーコード
                                                ,lv_item_errmsg);     --エラーメッセージ
            --型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --型・桁数チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_conclusion_day2
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_conclusion_day2
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
              --消化計算締め日チェックフラグFALSE
              lb_conc_day_chk_flg := FALSE;
            ELSE
              --範囲チェック
              IF  ( (TO_NUMBER(lv_conclusion_day2) < cn_conc_day_min)
                OR  (TO_NUMBER(lv_conclusion_day2) > cn_conc_day_max) )
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --範囲チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_range_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_conclusion_day2
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_conclusion_day2
                                ,iv_token_name4  => cv_token_min_value
                                ,iv_token_value4 => cn_conc_day_min
                                ,iv_token_name5  => cv_token_max_value
                                ,iv_token_value5 => cn_conc_day_max
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
                --消化計算締め日チェックフラグFALSE
                lb_conc_day_chk_flg := FALSE;
              END IF;
            END IF;
          END IF;
--
          -- ===========================================
          -- 消化計算締め日3の取得・チェック
          -- ===========================================
          --消化計算締め日3取得
          lv_conclusion_day3 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.27 mod start
--                                                                       ,74);
                                                                       ,75);
-- Ver1.27 mod end
          --NULL以外かつ、'-'でない場合
          IF (NVL(lv_conclusion_day3 ,cv_null_bar) <> cv_null_bar)
          THEN
            --型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_conclusion_day3   --消化計算締め日3
                                                ,lv_conclusion_day3   --消化計算締め日3
                                                ,2                    --項目長
                                                ,0                    --項目長（小数点以下）
                                                ,cv_null_ok           --必須フラグ
                                                ,cv_element_num       --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf       --エラーバッファ
                                                ,lv_item_retcode      --エラーコード
                                                ,lv_item_errmsg);     --エラーメッセージ
            --型・桁数チェックエラー時
            IF (lv_item_retcode <> cv_status_normal)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --型・桁数チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_conclusion_day3
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_conclusion_day3
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
              --消化計算締め日チェックフラグFALSE
              lb_conc_day_chk_flg := FALSE;
            ELSE
              --範囲チェック
              IF  ( (TO_NUMBER(lv_conclusion_day3) < cn_conc_day_min)
                OR  (TO_NUMBER(lv_conclusion_day3) > cn_conc_day_max) )
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --範囲チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_range_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_conclusion_day3
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_conclusion_day3
                                ,iv_token_name4  => cv_token_min_value
                                ,iv_token_value4 => cn_conc_day_min
                                ,iv_token_name5  => cv_token_max_value
                                ,iv_token_value5 => cn_conc_day_max
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
                --消化計算締め日チェックフラグFALSE
                lb_conc_day_chk_flg := FALSE;
              END IF;
            END IF;
          END IF;
--
          -- ===========================================
          -- 消化計算締め日の妥当性チェック
          -- ===========================================
          --消化計算締め日チェックフラグがTRUEの場合
          IF (lb_conc_day_chk_flg = TRUE)
          THEN
            -- ===========================================
            --消化計算締め日1の更新値を取得
            -- ===========================================
            --設定値が'-'の場合
            IF (lv_conclusion_day1 = cv_null_bar)
            THEN
              lt_conclusion_day1_aft := NULL;
            --設定値がNULL以外かつ、'-'以外の場合
            ELSIF (NVL(lv_conclusion_day1 ,cv_null_bar) <> cv_null_bar)
            THEN
              lt_conclusion_day1_aft := TO_NUMBER(lv_conclusion_day1);
            ELSE
              lt_conclusion_day1_aft := lt_conclusion_day1_bef;
            END IF;
            --
            -- ===========================================
            --消化計算締め日2の更新値を取得
            -- ===========================================
            --設定値が'-'の場合
            IF (lv_conclusion_day2 = cv_null_bar)
            THEN
              lt_conclusion_day2_aft := NULL;
            --設定値がNULL以外かつ、'-'以外の場合
            ELSIF (NVL(lv_conclusion_day2 ,cv_null_bar) <> cv_null_bar)
            THEN
              lt_conclusion_day2_aft := TO_NUMBER(lv_conclusion_day2);
            ELSE
              lt_conclusion_day2_aft := lt_conclusion_day2_bef;
            END IF;
            --
            -- ===========================================
            --消化計算締め日3の更新値を取得
            -- ===========================================
            IF (lv_conclusion_day3 = cv_null_bar)
            THEN
              lt_conclusion_day3_aft := NULL;
            --設定値がNULL以外かつ、'-'以外の場合
            ELSIF (NVL(lv_conclusion_day3 ,cv_null_bar) <> cv_null_bar)
            THEN
              lt_conclusion_day3_aft := TO_NUMBER(lv_conclusion_day3);
            ELSE
              lt_conclusion_day3_aft := lt_conclusion_day3_bef;
            END IF;
--
            -- ===========================================
            -- 消化計算締め日1の相関チェック
            -- ===========================================
            IF    (lt_conclusion_day1_aft IS NULL)
              AND (lt_conclusion_day2_aft IS NOT NULL)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --消化計算締め日相関チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_conc_day_rel_err_msg
                              ,iv_token_name1  => cv_token_conc_day1
                              ,iv_token_value1 => cv_conclusion_day2
                              ,iv_token_name2  => cv_token_conc_day2
                              ,iv_token_value2 => cv_conclusion_day1
                              ,iv_token_name3  => cv_cust_code
                              ,iv_token_value3 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
--
            -- ===========================================
            -- 消化計算締め日2の相関チェック
            -- ===========================================
            IF    (lt_conclusion_day2_aft IS NULL)
              AND (lt_conclusion_day3_aft IS NOT NULL)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --消化計算締め日相関チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_conc_day_rel_err_msg
                              ,iv_token_name1  => cv_token_conc_day1
                              ,iv_token_value1 => cv_conclusion_day3
                              ,iv_token_name2  => cv_token_conc_day2
                              ,iv_token_value2 => cv_conclusion_day2
                              ,iv_token_name3  => cv_cust_code
                              ,iv_token_value3 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
--
            -- ===========================================
            -- 消化計算締め日2の妥当性チェック
            -- ===========================================
            IF    (lt_conclusion_day1_aft IS NOT NULL)
              AND (lt_conclusion_day2_aft IS NOT NULL)
            THEN
              --消化計算締め日1と消化計算締め日2の日付間隔チェック
              IF  lt_conclusion_day2_aft
                < lt_conclusion_day1_aft + cn_conclusion_interval
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --消化計算締め日妥当性チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_conc_day_val_err_msg
                                ,iv_token_name1  => cv_token_conc_day1
                                ,iv_token_value1 => cv_conclusion_day2
                                ,iv_token_name2  => cv_token_conc_day2
                                ,iv_token_value2 => cv_conclusion_day1
                                ,iv_token_name3  => cv_token_interval
                                ,iv_token_value3 => cn_conclusion_interval
                                ,iv_token_name4  => cv_cust_code
                                ,iv_token_value4 => lv_customer_code
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
--
            -- ===========================================
            -- 消化計算締め日3の妥当性チェック
            -- ===========================================
            IF    (lt_conclusion_day2_aft IS NOT NULL)
              AND (lt_conclusion_day3_aft IS NOT NULL)
            THEN
              --消化計算締め日2と消化計算締め日3の日付間隔チェック
              IF  lt_conclusion_day3_aft
                < lt_conclusion_day2_aft + cn_conclusion_interval
              THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --消化計算締め日妥当性チェックエラーメッセージ取得
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_conc_day_val_err_msg
                                ,iv_token_name1  => cv_token_conc_day1
                                ,iv_token_value1 => cv_conclusion_day3
                                ,iv_token_name2  => cv_token_conc_day2
                                ,iv_token_value2 => cv_conclusion_day2
                                ,iv_token_name3  => cv_token_interval
                                ,iv_token_value3 => cn_conclusion_interval
                                ,iv_token_name4  => cv_cust_code
                                ,iv_token_value4 => lv_customer_code
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
--
            -- ===========================================
            -- 消化計算締め日の月末日付チェック
            -- ===========================================
            --業態(小分類)が消化VDの場合、消化計算締め日1〜3の何れかに
            --月末日付：30が設定されているかチェック
            IF    (lt_business_low_type_aft = cv_gyotai_syoka_vd )
              AND (NVL(lt_conclusion_day1_aft ,cn_dummy_0) <> cn_conc_day_max)
              AND (NVL(lt_conclusion_day2_aft ,cn_dummy_0) <> cn_conc_day_max)
              AND (NVL(lt_conclusion_day3_aft ,cn_dummy_0) <> cn_conc_day_max)
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --消化計算締め日月末日チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_conc_day_lastday_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          END IF;
--
          -- ===========================================
          -- 店舗営業用顧客コードの取得・チェック
          -- ===========================================
          --店舗営業用顧客コード取得
          lv_store_cust_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- Ver1.27 mod start
--                                                                       ,75);
                                                                       ,76);
-- Ver1.27 mod end
          --店舗営業用顧客コードが'-'でない場合
          IF (NVL(lv_store_cust_code ,cv_null_bar) <> cv_null_bar)
          THEN
            --マスタ存在チェック
            << check_store_cust_code_loop >>
            FOR check_store_cust_code_rec IN check_store_cust_code_cur( lv_store_cust_code )
            LOOP
              lt_store_cust_code_aft := check_store_cust_code_rec.store_cust_code;
            END LOOP check_store_cust_code_loop;
            --
            IF (lt_store_cust_code_aft IS NULL)
            THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --マスタ存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_store_cust_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_store_cust_code
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_cust_acct_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          END IF;
-- Ver1.16 add start
          --相殺用顧客コード取得
          lv_offset_cust_code := xxccp_common_pkg.char_delim_partition( lv_temp
                                                                      , cv_comma
-- Ver1.27 mod start
--                                                                      , 77
--                                                                      );
                                                                      ,78);
-- Ver1.27 mod end
--
          --CSV値が任意の値の場合
          IF ( NVL( lv_offset_cust_code ,cv_null_bar ) <> cv_null_bar ) THEN
            --マスタ存在チェック
            << check_offset_cust_code_loop >>
            FOR check_offset_cust_code_rec IN check_offset_cust_code_cur( lv_offset_cust_code )
            LOOP
              lt_offset_cust_code_mst := check_offset_cust_code_rec.offset_cust_code;
            END LOOP check_offset_cust_code_loop;
            --
            IF ( lt_offset_cust_code_mst IS NULL )
            THEN
              --エラーセット
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --マスタ存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_offset_cust_div_err_msg
                              ,iv_token_name1  => cv_value
                              ,iv_token_value1 => lv_offset_cust_code
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                            );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              --相殺用顧客関連チェックフラグ
              lb_offset_cust_chk_flg := FALSE;
            END IF;
          END IF;
--
          --取引先顧客コード取得
          lv_bp_customer_code := xxccp_common_pkg.char_delim_partition( lv_temp
                                                                      , cv_comma
-- Ver1.27 mod start
--                                                                      , 78
--                                                                      );
                                                                      ,79);
-- Ver1.27 mod end
--
          --CSV値が任意の値の場合
          IF ( NVL( lv_bp_customer_code ,cv_null_bar ) <> cv_null_bar ) THEN
            --型・桁数チェック
            xxccp_common_pkg2.upload_item_check( cv_bp_customer_code     --項目名称
                                                ,lv_bp_customer_code     --取引先顧客コード
                                                ,15                      --項目長
                                                ,NULL                    --項目長（小数点以下）
                                                ,cv_null_ok              --必須フラグ
                                                ,cv_element_vc2          --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf          --エラーバッファ
                                                ,lv_item_retcode         --エラーコード
                                                ,lv_item_errmsg          --エラーメッセージ
                                               );
            --型・桁数チェックエラー時
            IF ( lv_item_retcode <> cv_status_normal ) THEN
              --エラーセット
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --取引先顧客コードエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_bp_customer_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_bp_customer_code
                            );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              --相殺用顧客関連チェックフラグ
              lb_offset_cust_chk_flg := FALSE;
            END IF;
          END IF;
--
          --相殺用顧客関連チェックフラグがTRUEの場合
          IF ( lb_offset_cust_chk_flg = TRUE )
          THEN
            -- ===========================================
            -- 相殺用顧客コードの更新値を取得
            -- ===========================================
            --設定値が'-'の場合
            IF ( lv_offset_cust_code = cv_null_bar )
            THEN
              lt_offset_cust_code_aft := NULL;
            --設定値がNULL以外かつ、'-'以外の場合
            ELSIF ( NVL(lv_offset_cust_code ,cv_null_bar) <> cv_null_bar )
            THEN
              lt_offset_cust_code_aft := lv_offset_cust_code;
            ELSE
              lt_offset_cust_code_aft := lt_offset_cust_code_bef;
            END IF;
--
            -- ===========================================
            -- 取引先顧客コードの更新値を取得
            -- ===========================================
            --設定値が'-'の場合
            IF ( lv_bp_customer_code = cv_null_bar )
            THEN
              lt_bp_customer_code_aft := NULL;
            --設定値がNULL以外かつ、'-'以外の場合
            ELSIF ( NVL(lv_bp_customer_code ,cv_null_bar) <> cv_null_bar )
            THEN
              lt_bp_customer_code_aft := lv_bp_customer_code;
            ELSE
              lt_bp_customer_code_aft := lt_bp_customer_code_bef;
            END IF;
--
            -- ===========================================
            -- 相殺用顧客コード関連チェック
            -- ===========================================
            --相殺用顧客に相殺用顧客コードを設定する場合エラー
            IF  ( lt_offset_cust_div = cv_offset_cust_div_1 )
              AND ( lt_offset_cust_code_aft IS NOT NULL )
            THEN
              --エラーセット
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --相殺用顧客コード関連チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_offset_cust_rel_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
--
            -- ===========================================
            -- 取引先顧客コード重複チェック
            -- ===========================================
            --取引先顧客コード重複チェック
            << chk_bp_customer_code_loop >>
            FOR chk_bp_customer_code_rec IN chk_bp_customer_code_cur( lt_offset_cust_code_aft   -- 相殺用顧客コード
                                                                    , lt_bp_customer_code_aft   -- 取引先顧客コード
                                                                    , lv_customer_code          -- 顧客コード
                                                                    )
            LOOP
              lv_bp_cust_exists := chk_bp_customer_code_rec.bp_cust_exists;
            END LOOP chk_bp_customer_code_loop;
            --既存レコードが取得された場合
            IF ( lv_bp_cust_exists IS NOT NULL )
            THEN
              --エラーセット
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --取引先顧客コード重複チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_bp_cust_exists_err_msg
                              ,iv_token_name1  => cv_value
                              ,iv_token_value1 => lt_offset_cust_code_aft
                              ,iv_token_name2  => cv_value2
                              ,iv_token_value2 => lt_bp_customer_code_aft
                              ,iv_token_name3  => cv_cust_code
                              ,iv_token_value3 => lv_customer_code
                            );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
--
          END IF;
-- Ver1.16 add end
        END IF;
-- Ver1.10 add end
-- Ver1.14 add start
        --ストレポ＆商談くん連携対象フラグ取得
        lv_esm_target_div := xxccp_common_pkg.char_delim_partition( lv_temp
                                                                  , cv_comma
-- Ver1.27 mod start
--                                                                 , 76
--                                                                  );
                                                                  ,77);
-- Ver1.27 mod end
--
        --CSV値が任意の値の場合
        IF ( NVL( lv_esm_target_div ,cv_null_bar ) <> cv_null_bar ) THEN
          --参照表存在チェック(使用可能='Y')
          << check_esm_target_div_loop >>
          FOR check_lookup_type_rec2 IN check_lookup_type_cur2( lv_esm_target_div
                                                              , cv_lkp_esm_target_div )
          LOOP
            lt_esm_target_div_mst := check_lookup_type_rec2.lookup_code;
          END LOOP check_esm_target_div_loop;
          --
          IF ( lt_esm_target_div_mst IS NULL )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --参照表存在チェックエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_esm_target_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_esm_target_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
        END IF;
-- Ver1.14 add end
-- Ver1.19 add start
        --カテゴリー商品計上区分取得
        lv_latitude := xxccp_common_pkg.char_delim_partition( lv_temp
                                                            , cv_comma
-- Ver1.27 mod start
--                                                            , 82
--                                                            );
                                                            ,83);
-- Ver1.27 mod end
--
        -- カテゴリー商品計上区分必須チェック
-- Ver1.20 add start
        IF (lv_cust_customer_class = cv_kokyaku_kbn ) THEN
-- Ver1.20 add end
          <<check_unn_loop>>
          -- 業態小分類がカテゴリー商品計上区分不要対象かチェック
          FOR check_cat_prod_unn_rec IN check_cat_prod_unn_cur( lt_business_low_type_aft )
          LOOP
            ln_cnt := check_cat_prod_unn_rec.cnt;
          END LOOP check_unn_loop;
          --
          -- 不要対象外の場合、カテゴリー商品計上区分が設定されているかチェック
          IF (ln_cnt = 0) THEN
            IF   ((lv_latitude = cv_null_bar)
              OR  (NVL(lv_latitude, lt_latitude_bef) IS NULL))
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --カテゴリー商品計上区分必須チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_latitude_exists_err_mst
                              ,iv_token_name1  => cv_input_data
                              ,iv_token_value1 => lt_business_low_type_aft
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          END IF;
          --
          --CSV値が任意の値の場合
          IF ( NVL( lv_latitude ,cv_null_bar ) <> cv_null_bar ) THEN
            --参照表存在チェック(使用可能='Y')
            << check_latitude_loop >>
            FOR check_lookup_type_rec2 IN check_lookup_type_cur2( lv_latitude
                                                                , cv_lkp_cat_prod_div )
            LOOP
              lt_latitude_mst := check_lookup_type_rec2.lookup_code;
            END LOOP check_latitude_loop;
            --
            IF ( lt_latitude_mst IS NULL )
            THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --参照表存在チェックエラーメッセージ取得
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_latitude_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_latitude
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          END IF;
-- Ver1.19 add end
-- Ver1.20 add start
        ELSE  --顧客区分:10以外
          IF ( lv_latitude <> cv_null_bar ) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --カテゴリー商品計上区分指定エラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_latitude_not_null_err
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
        END IF;
-- Ver1.20 add end
-- Ver1.28 add start
        --POS企業コード取得
        lv_pos_enterprise_code := xxccp_common_pkg.char_delim_partition( lv_temp
                                                                        ,cv_comma
                                                                        ,86);
        --POS企業コードがNULL以外かつ、'-'でない場合
        IF (NVL(lv_pos_enterprise_code ,cv_null_bar) <> cv_null_bar)
        THEN
          --桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_pos_enterprise_code    --POS企業コード
                                              ,lv_pos_enterprise_code    --POS企業コード
                                              ,9                         --項目長
                                              ,NULL                      --項目長（小数点以下）
                                              ,cv_null_ok                --必須フラグ
                                              ,cv_element_vc2            --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf            --エラーバッファ
                                              ,lv_item_retcode           --エラーコード
                                              ,lv_item_errmsg);          --エラーメッセージ
          --POS企業コード9桁超えチェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --POS企業コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_pos_enterprise_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_pos_enterprise_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          --POS企業コード9桁未満チェックエラー時
          ELSIF (LENGTHB(lv_pos_enterprise_code) <> 9) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --POS企業コードエラーメッセージ取得
            xxccp_common_pkg2.upload_item_check( cv_pos_enterprise_code    --POS企業コード
                                                ,lv_pos_enterprise_code    --POS企業コード
                                                ,0                         --項目長
                                                ,NULL                      --項目長（小数点以下）
                                                ,cv_null_ok                --必須フラグ
                                                ,cv_element_vc2            --属性（0・検証なし、1、数値、2、日付）
                                                ,lv_item_errbuf            --エラーバッファ
                                                ,lv_item_retcode           --エラーコード
                                                ,lv_item_errmsg);          --エラーメッセージ
            --POS企業コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_pos_enterprise_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_pos_enterprise_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          --POS企業コード半角英数字チェック
          ELSIF (xxccp_common_pkg.chk_alphabet_number_only(lv_pos_enterprise_code) = FALSE) 
          THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --POS企業コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_pos_enterprise_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_pos_enterprise_code
                           );
            --半角英数字エラーメッセージ取得
            lv_item_errmsg := gv_cnst_err_msg_space12
                              || xxccp_common_pkg.get_msg(
                                    iv_application  => gv_xxcmm_msg_kbn
                                   ,iv_name         => cv_an_attr_msg
                                   ,iv_token_name1  => cv_item
                                   ,iv_token_value1 => cv_pos_enterprise_code
                                 );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
        --
        --POS店舗コード取得
        lv_pos_store_code := xxccp_common_pkg.char_delim_partition( lv_temp
                                                                   ,cv_comma
                                                                   ,87);
        --POS店舗コードがNULL以外かつ、'-'でない場合
        IF (NVL(lv_pos_store_code ,cv_null_bar) <> cv_null_bar)
        THEN
          --桁数チェック
          xxccp_common_pkg2.upload_item_check( cv_pos_store_code    --POS店舗コード
                                              ,lv_pos_store_code    --POS店舗コード
                                              ,9                    --項目長
                                              ,NULL                 --項目長（小数点以下）
                                              ,cv_null_ok           --必須フラグ
                                              ,cv_element_vc2       --属性（0・検証なし、1、数値、2、日付）
                                              ,lv_item_errbuf       --エラーバッファ
                                              ,lv_item_retcode      --エラーコード
                                              ,lv_item_errmsg);     --エラーメッセージ
          --POS店舗コード型・桁数チェックエラー時
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --POS店舗コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_pos_store_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_pos_store_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          --POS店舗コード半角英数字チェック
          ELSIF (xxccp_common_pkg.chk_alphabet_number_only(lv_pos_store_code) = FALSE)
          THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --POS店舗コードエラーメッセージ取得
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_pos_store_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_pos_store_code
                           );
            --半角英数字エラーメッセージ取得
            lv_item_errmsg := gv_cnst_err_msg_space12
                              || xxccp_common_pkg.get_msg(
                                    iv_application  => gv_xxcmm_msg_kbn
                                   ,iv_name         => cv_an_attr_msg
                                   ,iv_token_name1  => cv_item
                                   ,iv_token_value1 => cv_pos_store_code
                                 );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
-- Ver1.28 add end
        --
        IF (lv_check_status = cv_status_normal) THEN
          BEGIN
            INSERT INTO xxcmm_wk_cust_batch_regist(
               file_id
              ,customer_code
              ,customer_class_code
              ,customer_name
              ,customer_name_kana
              ,customer_name_ryaku
              ,customer_status
              ,approval_reason
              ,approval_date
              ,credit_limit
              ,decide_div
              ,ar_invoice_code
              ,ar_location_code
              ,ar_others_code
              ,invoice_class
              ,invoice_cycle
              ,invoice_form
              ,payment_term_id
              ,payment_term_second
              ,payment_term_third
              ,sales_chain_code
              ,delivery_chain_code
              ,policy_chain_code
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
              ,intro_chain_code1
              ,intro_chain_code2
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
              ,chain_store_code
              ,store_code
              ,business_low_type
              ,postal_code
              ,state
              ,city
              ,address1
              ,address2
              ,address3
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              ,invoice_code
-- Ver1.27 add start
              ,invoice_tax_div
-- Ver1.27 add end
              ,industry_div
              ,bill_base_code
              ,receiv_base_code
              ,delivery_base_code
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
              ,sales_head_base_code
              ,cnvs_base_code
              ,cnvs_business_person
              ,new_point_div
              ,new_point
              ,intro_base_code
              ,intro_business_person
              ,tdb_code
              ,corp_approval_date
              ,base_code
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
              ,selling_transfer_div
              ,card_company
              ,wholesale_ctrl_code
              ,price_list
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
              ,ship_storage_code
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
              ,delivery_order
              ,edi_district_code
              ,edi_district_name
              ,edi_district_kana
              ,tsukagatazaiko_div
              ,deli_center_code
              ,deli_center_name
              ,edi_forward_number
              ,cust_store_name
              ,torihikisaki_code
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
              ,vist_target_div           --訪問対象区分
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- Ver1.10 add start
              ,address_lines_phonetic    --電話番号
              ,address4                  --FAX
              ,sale_base_code            --売上拠点
              ,tax_div                   --消費税区分
              ,longitude                 --ピークカット開始時刻
              ,calendar_code             --稼働日カレンダ
              ,rate                      --消化計算用掛率
              ,receiv_discount_rate      --入金値引率
              ,conclusion_day1           --消化計算締め日1
              ,conclusion_day2           --消化計算締め日2
              ,conclusion_day3           --消化計算締め日3
              ,store_cust_code           --店舗営業用顧客コード
-- Ver1.10 add end
-- Ver1.14 add start
              ,esm_target_div            --ストレポ＆商談くん連携対象フラグ
-- Ver1.14 add end
-- Ver1.16 add start
              ,offset_cust_code          --相殺用顧客コード
              ,bp_customer_code          --取引先顧客コード
-- Ver1.16 add end
-- Ver1.19 add start
              ,latitude                  --カテゴリー商品計上区分
-- Ver1.19 add end
-- Ver1.28 add start
              ,pos_enterprise_code
              ,pos_store_code
-- Ver1.28 add end
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            )
            VALUES(
               in_file_id
              ,lv_customer_code
              ,lv_customer_class
              ,lv_customer_name
              ,lv_cust_name_kana
              ,lv_cust_name_ryaku
              ,lv_customer_status
              ,lv_approval_reason
              ,lv_approval_date
              ,ln_credit_limit
              ,lv_decide_div
              ,lv_ar_invoice_code
              ,lv_ar_location_code
              ,lv_ar_others_code
              ,lv_invoice_class
              ,lv_invoice_cycle
              ,lv_invoice_form
              ,lv_payment_term_id
              ,lv_payment_term_second
              ,lv_payment_term_third
              ,lv_sales_chain_code
              ,lv_delivery_chain_code
              ,lv_policy_chain_code
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
              ,lv_intro_chain_code1
              ,lv_intro_chain_code2
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
              ,lv_edi_chain_code
              ,lv_store_code
              ,lv_business_low_type
              ,lv_postal_code
              ,lv_state
              ,lv_city
              ,lv_address1
              ,lv_address2
              ,lv_address3
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              ,lv_invoice_code
-- Ver1.27 add start
              ,lv_invoice_tax_div
-- Ver1.27 add end
              ,lv_industry_div
              ,lv_bill_base_code
              ,lv_receiv_base_code
              ,lv_delivery_base_code
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
              ,lv_sales_head_base_code
              ,lv_cnvs_base_code
              ,lv_cnvs_business_person
              ,lv_new_point_div
              ,lv_new_point
              ,lv_intro_base_code
              ,lv_intro_business_person
              ,lv_tdb_code
              ,lv_corp_approval_date
              ,lv_base_code
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
              ,lv_selling_transfer_div
              ,lv_card_company
              ,lv_wholesale_ctrl_code
              ,lv_price_list
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
              ,lv_ship_storage_code
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
              ,lv_delivery_order
              ,lv_edi_district_code
              ,lv_edi_district_name
              ,lv_edi_district_kana
              ,lv_tsukagatazaiko_div
              ,lv_deli_center_code
              ,lv_deli_center_name
              ,lv_edi_forward_number
              ,lv_cust_store_name
              ,lv_torihikisaki_code
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
              ,lv_vist_target_div        --訪問対象区分
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- Ver1.10 add start
              ,lv_address_lines_phonetic      --電話番号
              ,lv_address4                    --FAX
              ,lv_sale_base_code              --売上拠点
              ,lv_tax_div                     --消費税区分
              ,lv_longitude                   --ピークカット開始時刻
              ,lv_calendar_code               --稼働日カレンダ
              ,lv_rate                        --消化計算用掛率
              ,lv_rcv_dsct_rate               --入金値引率
              ,lv_conclusion_day1             --消化計算締め日1
              ,lv_conclusion_day2             --消化計算締め日2
              ,lv_conclusion_day3             --消化計算締め日3
              ,lv_store_cust_code             --店舗営業用顧客コード
-- Ver1.10 add end
-- Ver1.14 add start
              ,lv_esm_target_div              --ストレポ＆商談くん連携対象フラグ
-- Ver1.14 add end
-- Ver1.16 add start
              ,lv_offset_cust_code            --相殺用顧客コード
              ,lv_bp_customer_code            --取引先顧客コード
-- Ver1.16 add end
-- Ver1.19 add start
              ,lv_latitude                    --カテゴリー商品計上区分
-- Ver1.19 add end
-- Ver1.28 add start
              ,lv_pos_enterprise_code         --POS企業コード
              ,lv_pos_store_code              --POS店舗コード
-- Ver1.28 add end
              ,fnd_global.user_id
              ,sysdate
              ,fnd_global.user_id
              ,sysdate
              ,fnd_profile.value(cv_conc_request_id)
              ,fnd_profile.value(cv_prog_appl_id)
              ,fnd_profile.value(cv_conc_program_id)
              ,sysdate
            );
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              lv_retcode := cv_status_error;
              RAISE invalid_data_expt;
          END;
        END IF;
        --件数カウント
        gn_target_cnt    := gn_target_cnt + 1;  -- 対象件数
        IF (lv_check_status = cv_status_normal) THEN
          gn_normal_cnt  := gn_normal_cnt + 1;  -- 正常件数
        ELSE
          gn_error_cnt   := gn_error_cnt +1;    -- エラー件数
        END IF;
      END IF;
      --各格納用変数初期化
      lv_temp                  := NULL;
      lv_item_retcode          := NULL;
      lv_item_errmsg           := NULL;
      lv_customer_code         := NULL;
      lv_cust_code_mst         := NULL;
      ln_cust_id               := NULL;
      ln_party_id              := NULL;
      ln_cust_addon_mst        := NULL;
-- Ver1.10 del start
--      lv_business_low_mst      := NULL;
-- Ver1.10 del end
-- Ver1.13 add start
      lv_business_low_mst      := NULL;
-- Ver1.13 add end
      lv_get_cust_status       := NULL;
      lv_appr_reason_mst       := NULL;
      ln_cust_corp_mst         := NULL;
      lv_customer_class        := NULL;
      lv_cust_class_mst        := NULL;
      lv_cust_status_mst       := NULL;
      lr_cust_wk_table         := NULL;
      lv_ar_invoice_code_mst   := NULL;
      lv_invoice_class_mst     := NULL;
      lv_invoice_cycle_mst     := NULL;
      lv_invoice_form_mst      := NULL;
      lv_payment_term_id_mst   := NULL;
      lv_payment_second_mst    := NULL;
      lv_payment_third_mst     := NULL;
      lv_sales_chain_code_mst  := NULL;
      lv_deliv_chain_code_mst  := NULL;
      lv_edi_chain_mst         := NULL;
      lv_cust_chiku_code_mst   := NULL;
      lv_credit_limit          := NULL;
      ln_credit_limit          := NULL;
      lv_decide_div_mst        := NULL;
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
      lv_cust_customer_class      := NULL;
      lv_invoice_required_flag    := NULL;
-- Ver1.15 add start
      lv_invoice_trust_flag       := NULL;  --業者委託時設定可否フラグ
-- Ver1.15 add end
      lv_invoice_code             := NULL;
      ln_invoice_code_mst         := NULL;
      lv_industry_div             := NULL;
      lv_industry_div_mst         := NULL;
      lv_bill_base_code           := NULL;
      lv_bill_base_code_mst       := NULL;
      lv_receiv_base_code         := NULL;
      lv_receiv_base_code_mst     := NULL;
      lv_delivery_base_code       := NULL;
      lv_delivery_base_code_mst   := NULL;
      lv_selling_transfer_div     := NULL;
      lv_selling_transfer_div_mst := NULL;
      lv_card_company             := NULL;
      lv_card_company_mst         := NULL;
      lv_wholesale_ctrl_code      := NULL;
      lv_wholesale_ctrl_code_mst  := NULL;
      lv_price_list               := NULL;
      lv_price_list_mst           := NULL;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
      lv_ship_storage_code        := NULL;
      lv_ship_storage_code_mst    := NULL;
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
      lv_delivery_order           := NULL;
      lv_edi_district_code        := NULL;
      lv_edi_district_name        := NULL;
      lv_edi_district_kana        := NULL;
      lv_tsukagatazaiko_div       := NULL;
      lv_tsukagatazaiko_div_mst   := NULL;
      lv_deli_center_code         := NULL;
      lv_deli_center_name         := NULL;
      lv_edi_forward_number       := NULL;
      lv_cust_store_name          := NULL;
      lv_torihikisaki_code        := NULL;
      lv_tsukagatazaiko_flag      := NULL;
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
      lv_vist_target_div          := NULL;  --訪問対象区分
-- 2012/04/19 Ver1.8 E_本稼動_09272 add start by S.Niki
      lv_vist_target_div_mst      := NULL;  --訪問対象区分確認用変数
-- 2012/04/19 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
      lv_cnvs_base_code           := NULL;  --獲得拠点コード
      lv_cnvs_base_code_mst1      := NULL;  --獲得拠点コード確認用変数1
      lv_cnvs_base_code_mst2      := NULL;  --獲得拠点コード確認用変数2
      lv_cnvs_business_person     := NULL;  --獲得営業員
      lv_cnvs_business_person_mst1 := NULL; --獲得営業員確認用変数1
      lv_cnvs_business_person_mst2 := NULL; --獲得営業員確認用変数2
      lv_base_code_flag1          := NULL;  --獲得拠点コード入力チェック用1
      lv_business_person_flag1    := NULL;  --獲得営業員入力チェック用1
      lv_base_code_flag2          := NULL;  --獲得拠点コード入力チェック用2
      lv_business_person_flag2    := NULL;  --獲得営業員入力チェック用2
      lv_base_code_flag3          := NULL;  --獲得拠点コード入力チェック用3
      lv_business_person_flag3    := NULL;  --獲得営業員入力チェック用3
      lv_base_code_flag4          := NULL;  --獲得拠点コード入力チェック用4
      lv_business_person_flag4    := NULL;  --獲得営業員入力チェック用4
      lv_new_point_div            := NULL;  --新規ポイント区分
      lv_new_point_div_mst        := NULL;  --新規ポイント区分チェック用
      lv_new_point                := NULL;  --新規ポイント
      ln_new_point                := NULL;  --新規ポイント(数値)
      lv_intro_base_code          := NULL;  --紹介拠点
      lv_intro_base_code_mst1     := NULL;  --紹介拠点コード確認用1
      lv_intro_base_code_mst2     := NULL;  --紹介拠点コード確認用2
      lv_intro_business_person    := NULL;  --紹介営業員
      lv_intro_business_person_mst1 := NULL;  --紹介営業員チェック用1
      lv_intro_business_person_mst2 := NULL;  --紹介営業員チェック用2
      lv_int_bus_per_flag1        := NULL;  --紹介営業員チェック用1
      lv_int_bus_per_flag2        := NULL;  --紹介営業員チェック用2
      lv_base_code                := NULL;  --本部担当拠点
      lv_base_code_mst            := NULL;  --本部担当拠点チェック用
      lv_tdb_code                 := NULL;  --TDBコード
      lv_corp_approval_date       := NULL;  --決裁日付
      lv_intro_chain_code1        := NULL;  --紹介者チェーンコード１
      lv_intro_chain_code2        := NULL;  --控除用チェーンコード
      lv_sales_head_base_code     := NULL;  --販売先本部担当拠点
      lv_sales_head_base_code_mst := NULL;  --販売先本部担当拠点チェック用
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
      lt_business_low_type_bef    := NULL;  --現在値・業態(小分類)
      lt_business_low_type_aft    := NULL;  --更新値・業態(小分類)
      lt_sell_trans_div_bef       := NULL;  --現在値・売上実績振替
      lt_sell_trans_div_aft       := NULL;  --更新値・売上実績振替
      lt_tsukagatazaiko_div_bef   := NULL;  --現在値・通過在庫型区分
      lt_tsukagatazaiko_div_aft   := NULL;  --更新値・通過在庫型区分
      lt_ship_storage_code_bef    := NULL;  --現在値・出荷元保管場所
      lt_ship_storage_code_aft    := NULL;  --更新値・出荷元保管場所
      lt_ship_storage_code_mst    := NULL;  --出荷元保管場所確認用変数
      lt_chain_store_code_bef     := NULL;  --現在値・チェーン店コード(EDI)
      lt_chain_store_code_aft     := NULL;  --更新値・チェーン店コード(EDI)
      lt_chain_store_code_mst     := NULL;  --チェーン店コード(EDI)確認用変数
      lt_delivery_base_code_bef   := NULL;  --現在値・納品拠点
      lt_delivery_base_code_aft   := NULL;  --更新値・納品拠点
      lv_sale_base_code           := NULL;  --ローカル変数・売上拠点
      lt_sale_base_code_aft       := NULL;  --更新値・売上拠点
      lv_address_lines_phonetic   := NULL;  --ローカル変数・電話番号
      lv_address4                 := NULL;  --ローカル変数・FAX
      lv_tax_div                  := NULL;  --ローカル変数・消費税区分
      lt_tax_div_aft              := NULL;  --更新値・消費税区分
      lv_longitude                := NULL;  --ローカル変数・ピークカット開始時刻
      lt_longitude_bef            := NULL;  --現在値・ピークカット開始時刻
      lt_longitude_aft            := NULL;  --更新値・ピークカット開始時刻
      lv_calendar_code            := NULL;  --ローカル変数・稼働日カレンダ
      lt_calendar_code_aft        := NULL;  --更新値・稼働日カレンダ
      lv_rate                     := NULL;  --ローカル変数・消化計算用掛率
      lt_rate_bef                 := NULL;  --現在値・消化計算用掛率
      lv_rcv_dsct_rate            := NULL;  --ローカル変数・入金値引率
      lv_conclusion_day1          := NULL;  --ローカル変数・消化計算締め日1
      lt_conclusion_day1_bef      := NULL;  --現在値・消化計算締め日1
      lt_conclusion_day1_aft      := NULL;  --更新値・消化計算締め日1
      lv_conclusion_day2          := NULL;  --ローカル変数・消化計算締め日2
      lt_conclusion_day2_bef      := NULL;  --現在値・消化計算締め日2
      lt_conclusion_day2_aft      := NULL;  --更新値・消化計算締め日2
      lv_conclusion_day3          := NULL;  --ローカル変数・消化計算締め日3
      lt_conclusion_day3_bef      := NULL;  --現在値・消化計算締め日3
      lt_conclusion_day3_aft      := NULL;  --更新値・消化計算締め日3
      lv_store_cust_code          := NULL;  --ローカル変数・店舗営業用顧客コード
      lt_store_cust_code_aft      := NULL;  --更新値・店舗営業用顧客コード
-- Ver1.12 add start
      lt_invoice_form_bef         := NULL;  --現在値・請求書出力形式
      lt_invoice_form_aft         := NULL;  --更新値・請求書出力形式
      lt_invoice_cycle_bef        := NULL;  --現在値・請求書発行サイクル
      lt_invoice_cycle_aft        := NULL;  --更新値・請求書発行サイクル
-- Ver1.12 add end
-- Ver1.14 add start
      lv_esm_target_div           := NULL;  --ローカル変数・ストレポ＆商談くん連携対象フラグ
      lt_esm_target_div_mst       := NULL;  --ストレポ＆商談くん連携対象フラグ確認用変数
-- Ver1.14 add end
-- Ver1.15 add start
      lt_invoice_code_bef         := NULL;  --現在値・請求書用コード
      lt_invoice_code_aft         := NULL;  --更新値・請求書用コード
      lt_invoice_class_bef        := NULL;  --現在値・請求書印刷単位
      lt_invoice_class_aft        := NULL;  --更新値・請求書印刷単位
-- Ver1.15 add end
-- Ver1.16 add start
      lt_offset_cust_div          := NULL;  --相殺用顧客区分確認用変数
      lv_offset_cust_code         := NULL;  --ローカル変数・相殺用顧客コード
      lt_offset_cust_code_mst     := NULL;  --相殺用顧客コード確認用変数
      lt_offset_cust_code_bef     := NULL;  --現在値・相殺用顧客コード
      lt_offset_cust_code_aft     := NULL;  --更新値・相殺用顧客コード
      lv_bp_customer_code         := NULL;  --ローカル変数・取引先顧客コード
      lt_bp_customer_code_bef     := NULL;  --現在値・取引先顧客コード
      lt_bp_customer_code_aft     := NULL;  --更新値・取引先顧客コード
      lv_bp_cust_exists           := NULL;  --取引先顧客コード重複チェック用変数
-- Ver1.16 add end
-- Ver1.19 add start
      lv_latitude                 := NULL;  --ローカル変数・カテゴリー商品計上区分
      lt_latitude_bef             := NULL;  --現在値・カテゴリー商品計上区分
      lt_latitude_mst             := NULL;  --LOOKUP確認用・カテゴリー商品計上区分
      ln_cnt                      := NULL;  --カテゴリー商品計上区分不要対象件数
-- Ver1.19 add end
-- Ver1.27 add start
      lv_invoice_tax_div          := NULL;  --ローカル変数・請求書消費税積上げ計算方式
-- Ver1.27 add end
-- Ver1.23 add start
      lv_dedu_chain_code_mst      := NULL;  --控除用チェーンコード存在確認用変数
-- Ver1.23 add end
-- Ver1.28 add start
      lv_pos_enterprise_code      := NULL;  --ローカル変数・POS企業コード
      lv_pos_store_code           := NULL;  --ローカル変数・POS店舗コード
      lt_pos_enterprise_code      := NULL;  --現在値・POS企業コード
      lt_pos_store_code           := NULL;  --現在値・POS店舗コード
-- Ver1.28 add end
      --妥当性チェックフラグ
      lb_bz_low_type_chk_flg      := TRUE;  --業態(小分類)チェックフラグ
      lb_sell_trans_chk_flg       := TRUE;  --売上実績振替チェックフラグ
      lb_db_code_chk_flg          := TRUE;  --納品拠点チェックフラグ
      lb_tsukazaiko_chk_flg       := TRUE;  --通過在庫型区分チェックフラグ
      lb_sp_strg_code_chk_flg     := TRUE;  --出荷元保管場所チェックフラグ
      lb_cs_code_chk_flg          := TRUE;  --チェーン店コード(EDI)チェックフラグ
      lb_conc_day_chk_flg         := TRUE;  --消化計算締め日チェックフラグ
-- Ver1.10 add end
-- Ver1.12 add start
      lb_invoice_chk_flg          := TRUE;  --請求書関連チェックフラグ
-- Ver1.12 add end
-- Ver1.16 add start
      lb_offset_cust_chk_flg      := TRUE;  --相殺用顧客関連チェックフラグ
-- Ver1.16 add end
    END LOOP cust_data_wk_loop;
--
    --データエラー時メッセージ設定（コンカレント出力）
    IF (lv_retcode <> cv_status_normal) THEN
      --データエラー時メッセージ取得
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_xxcmm_msg_kbn
                      ,iv_name         => cv_invalid_data_msg
                     );
      lv_errmsg := gv_out_msg;
      lv_errbuf := gv_out_msg;
      RAISE invalid_data_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    WHEN get_csv_err_expt THEN                         --*** 顧客一括更新用CSV取得失敗例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN invalid_data_expt THEN                        --*** 顧客一括更新情報不正例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END cust_data_make_wk;
--
  /**********************************************************************************
   * Procedure Name   : rock_and_update_cust
   * Description      : テーブルロック処理(A-3)・顧客一括更新処理(A-4)
   ***********************************************************************************/
  PROCEDURE rock_and_update_cust(
    in_file_id              IN  NUMBER,              --   ファイルID
    ov_errbuf               OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'rock_and_update_cust'; -- プログラム名
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
-- Ver1.12 del start
--    cv_bill_to               CONSTANT VARCHAR2(7)     := 'BILL_TO';               --使用目的・請求先
--    cv_other_to              CONSTANT VARCHAR2(8)     := 'OTHER_TO';              --使用目的・その他
-- Ver1.12 del end
-- 2009/10/23 Ver1.2 delete start by Yutaka.Kuboshima
--    cv_aff_dept              CONSTANT VARCHAR2(15)    := 'XX03_DEPARTMENT';       --AFF部門マスタ参照タイプ
-- 2009/10/23 Ver1.2 delete end by Yutaka.Kuboshima
    cv_chain_code            CONSTANT VARCHAR2(16)    := 'XXCMM_CHAIN_CODE';      --参照コード：チェーン店参照タイプ
    cv_null_x                CONSTANT VARCHAR2(1)     := 'X';                     --NVL用ダミー文字列
    cn_zero                  CONSTANT NUMBER(1)       := 0;                       --NVL用ダミー数値
    cv_customer              CONSTANT VARCHAR2(2)     := '10';                    --顧客区分・顧客
    cv_su_customer           CONSTANT VARCHAR2(2)     := '12';                    --顧客区分・上様顧客
    cv_trust_corp            CONSTANT VARCHAR2(2)     := '13';                    --顧客区分・法人管理先
    cv_ar_manage             CONSTANT VARCHAR2(2)     := '14';                    --顧客区分・売掛管理先顧客
    cv_yes_output            CONSTANT VARCHAR2(1)     := 'Y';                     --出力有無・有
    cv_no_output             CONSTANT VARCHAR2(1)     := 'N';                     --出力有無・無
    cv_corp_no_data          CONSTANT VARCHAR2(20)    := '顧客法人情報未登録。';  --顧客法人情報未設定
    cv_addon_cust_no_data    CONSTANT VARCHAR2(20)    := '顧客追加情報未登録。';  --顧客追加情報未設定
    cv_sales_base_class      CONSTANT VARCHAR2(1)     := '1';                     --顧客区分・拠点
    cv_ignore                CONSTANT VARCHAR2(1)     := 'I';                     --顧客マスタ・ステータス無効
    cv_ng_word               CONSTANT VARCHAR2(7)     := 'NG_WORD';               --CSV出力エラートークン・NG_WORD
    cv_err_cust_code_msg     CONSTANT VARCHAR2(16)    := 'エラー顧客コード';      --CSV出力エラー文字列
    cv_ng_data               CONSTANT VARCHAR2(7)     := 'NG_DATA';               --CSV出力エラートークン・NG_DATA
    cv_success_api           CONSTANT VARCHAR2(1)     := 'S';                     --API成功時返却ステータス
    cv_init_list_api         CONSTANT VARCHAR2(1)     := 'T';                     --API起動初期リスト設定値
    cv_user_entered          CONSTANT VARCHAR2(12)    := 'USER_ENTERED';          --パーティマスタ更新ＡＰＩコンテンツソースタイプ
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    cv_ship_to               CONSTANT VARCHAR2(7)     := 'SHIP_TO';               --使用目的・出荷先
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/27 Ver1.4 E_本稼動_01280 add start by Yutaka.Kuboshima
-- Ver1.12 del start
--    cv_a_flag                CONSTANT VARCHAR2(1)     := 'A';                     --ステータス(有効)
-- Ver1.12 del end
-- 2010/01/27 Ver1.4 E_本稼動_01280 add start by Yutaka.Kuboshima
--
    -- *** ローカル変数 ***
    lv_header_str                     VARCHAR2(2000)  := NULL;                    --ヘッダメッセージ格納用変数
    lv_output_str                     VARCHAR2(2047)  := NULL;                    --出力文字列格納用変数
    ln_output_cnt                     NUMBER          := 0;                       --出力件数
    lv_sales_kigyou_code              fnd_flex_values.attribute1%TYPE;            --企業コード（販売先）格納用変数
    lv_delivery_kigyou_code           fnd_flex_values.attribute1%TYPE;            --企業コード（納品先）格納用変数
    lv_output_excute                  VARCHAR2(1)     := 'Y';                     --出力有無
    ln_credit_limit                   xxcmm_mst_corporate.credit_limit%TYPE;      --顧客法人情報.与信限度額
    lv_decide_div                     xxcmm_mst_corporate.decide_div%TYPE;        --顧客法人情報.判定区分
    lv_information                    VARCHAR2(100)   := NULL;
    lv_sales_base_name                VARCHAR2(50)    := NULL;
-- Ver1.14 add start
    lv_esm_cust_class                 VARCHAR2(2)     := NULL;                    --eSM対象顧客区分確認用変数
-- Ver1.14 add end
--
    --顧客更新ＡＰＩ用変数
    p_cust_account_rec                HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    ln_cust_object_version_number     NUMBER;
--
    --パーティ更新ＡＰＩ用変数
    ln_party_id                       NUMBER;
    lv_content_source_type            VARCHAR2(12);
    p_party_rec                       HZ_PARTY_V2PUB.PARTY_REC_TYPE;
    p_organization_rec                HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    ln_party_object_version_number    NUMBER;
    ln_profile_id                     NUMBER;
--
    --顧客使用目的更新ＡＰＩ用変数
    p_cust_site_use_rec               HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    ln_csu_object_version_number      NUMBER;
    ln_payment_term_id                NUMBER;
    ln_payment_term_second_id         NUMBER;
    ln_payment_term_third_id          NUMBER;
--
    --顧客事業所更新ＡＰＩ用変数
    p_location_rec                    HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    ln_location_object_version_num    NUMBER;
--
    --ＡＰＩ用汎用変数
    lv_return_status                  VARCHAR2(1);
    ln_msg_count                      NUMBER;
    lv_msg_data                       VARCHAR2(2000);
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- 顧客使用目的マスタ出荷先レコード更新ＡＰＩ用変数
    p_cust_site_use_ship_rec          HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    ln_csu_ship_object_number         NUMBER;
    ln_price_list                     NUMBER;
--
    -- 顧客追加情報マスタ更新用変数
    l_xxcmm_cust_accounts             xxcmm_cust_accounts%ROWTYPE;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
    -- 顧客法人情報マスタ更新用変数
    l_xxcmm_mst_corporate             xxcmm_mst_corporate%ROWTYPE;
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 顧客一括更新情報カーソル
    CURSOR cust_data_cur(
      in_file_id_wk IN NUMBER )
    IS
      SELECT  hca.cust_account_id         customer_id,                --顧客ID
              hca.account_number          customer_number,            --顧客番号
              hca.object_version_number   cust_ovn,                   --顧客オブジェクト世代番号
              hca.party_id                party_id,                   --パーティID
              hp.object_version_number    party_ovn,                  --パーティオブジェクト世代番号
              hcsu.site_use_id            site_use_id,                --顧客使用目的ID
              hcsu.bill_to_site_use_id    bill_to_site_use_id,        --顧客請求先使用目的ID
              hcsu.object_version_number  site_use_ovn,               --顧客使用目的オブジェクト世代番号
              hl.location_id              location_id,                --ロケーションID
              hl.object_version_number    location_ovn,               --ロケーションオブジェクト世代番号
              xca.stop_approval_reason    addon_approval_reason,      --顧客追加情報・中止理由
              xca.stop_approval_date      addon_approval_date,        --顧客追加情報・中止決済日
              xca.sales_chain_code        addon_sales_chain_code,     --顧客追加情報・チェーン店コード（販売先）
              xca.delivery_chain_code     addon_delivery_chain_code,  --顧客追加情報・チェーン店コード（納品先）
              xca.policy_chain_code       addon_policy_chain_code,    --顧客追加情報・チェーン店コード（営業政策用）
              xca.business_low_type       addon_business_low_type,    --顧客追加情報・業態（小分類）
              xca.chain_store_code        addon_chain_store_code,     --顧客追加情報・チェーン店コード（ＥＤＩ）
              xca.store_code              addon_store_code,           --顧客追加情報・中止決済日
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              xca.invoice_printing_unit   addon_invoice_class,        --顧客追加情報・請求書印刷単位
              xca.invoice_code            addon_invoice_code,         --顧客追加情報・請求書用コード
              xca.industry_div            addon_industry_div,         --顧客追加情報・業種
              xca.bill_base_code          addon_bill_base_code,       --顧客追加情報・請求拠点
              xca.receiv_base_code        addon_receiv_base_code,     --顧客追加情報・入金拠点
              xca.delivery_base_code      addon_delivery_base_code,   --顧客追加情報・納品拠点
              xca.selling_transfer_div    addon_selling_transfer_div, --顧客追加情報・売上実績振替
              xca.card_company            addon_card_company,         --顧客追加情報・カード会社
              xca.wholesale_ctrl_code     addon_wholesale_ctrl_code,  --顧客追加情報・問屋管理コード
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
              xmc.credit_limit            addon_credit_limit,         --顧客法人情報・与信限度額
              xmc.decide_div              addon_decide_div,           --顧客法人情報・判定区分
              xwcbr.customer_name         customer_name,              --顧客名称
              xwcbr.customer_name_kana    customer_name_kana,         --顧客名称カナ
              xwcbr.customer_name_ryaku   customer_name_ryaku,        --略称
              xwcbr.customer_status       customer_status,            --顧客ステータス
              xwcbr.ar_invoice_code       ar_invoice_code,            --売掛コード１（請求書）
              xwcbr.ar_location_code      ar_location_code,           --売掛コード２（事業所）
              xwcbr.ar_others_code        ar_others_code,             --売掛コード３（その他）
              xwcbr.invoice_class         invoice_class,              --請求書印刷単位
              xwcbr.invoice_cycle         invoice_cycle,              --請求書発行サイクル
              xwcbr.invoice_form          invoice_form,               --請求書出力形式
              xwcbr.payment_term_id       payment_term_id,            --支払条件
              xwcbr.payment_term_second   payment_term_second,        --第2支払条件
              xwcbr.payment_term_third    payment_term_third,         --第3支払条件
              xwcbr.postal_code           postal_code,                --郵便番号
              xwcbr.state                 state,                      --都道府県
              xwcbr.city                  city,                       --市・区
              xwcbr.address1              address1,                   --住所1
              xwcbr.address2              address2,                   --住所2
              xwcbr.address3              address3,                   --地区コード
              xwcbr.approval_reason       approval_reason,            --中止理由
              xwcbr.approval_date         approval_date,              --中止決済日
              xwcbr.sales_chain_code      sales_chain_code,           --チェーン店コード（販売先）
              xwcbr.delivery_chain_code   delivery_chain_code,        --チェーン店コード（納品先）
              xwcbr.policy_chain_code     policy_chain_code,          --チェーン店コード（営業政策用）
              xwcbr.chain_store_code      chain_store_code,           --チェーン店コード（ＥＤＩ）
              xwcbr.store_code            store_code,                 --店舗コード
              xwcbr.business_low_type     business_low_type,          --業態（小分類）
              xwcbr.credit_limit          credit_limit,               --与信限度額
              xwcbr.decide_div            decide_div,                 --判定区分
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              xwcbr.invoice_code          invoice_code,               --請求書用コード
-- Ver1.27 add start
              xwcbr.invoice_tax_div       invoice_tax_div,            --請求書消費税積上げ計算方式
              xca.invoice_tax_div         addon_invoice_tax_div,      --顧客追加情報・請求書消費税積上げ計算方式
-- Ver1.27 add end
              xwcbr.industry_div          industry_div,               --業種
              xwcbr.bill_base_code        bill_base_code,             --請求拠点
              xwcbr.receiv_base_code      receiv_base_code,           --入金拠点
              xwcbr.delivery_base_code    delivery_base_code,         --納品拠点
              xwcbr.selling_transfer_div  selling_transfer_div,       --売上実績振替
              xwcbr.card_company          card_company,               --カード会社
              xwcbr.wholesale_ctrl_code   wholesale_ctrl_code,        --問屋管理コード
              xwcbr.price_list            price_list,                 --価格表
              hcas.cust_acct_site_id      cust_acct_site_id,          --所在地ID
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
--
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--              xwcbr.customer_class_code   customer_class_code         --顧客区分
              hca.customer_class_code     customer_class_code         --顧客区分
-- 2009/10/23 Ver1.2 modify end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
             ,xca.past_customer_status    addon_past_customer_status  --顧客追加情報・前月顧客ステータス
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
             ,xwcbr.ship_storage_code     ship_storage_code           --出荷元保管場所
             ,xca.ship_storage_code       addon_ship_storage_code     --顧客追加情報・出荷元保管場所
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
             ,xwcbr.delivery_order        delivery_order              --配送順（EDI）
             ,xca.delivery_order          addon_delivery_order        --顧客追加情報・配送順（EDI）
             ,xwcbr.edi_district_code     edi_district_code           --EDI地区コード（EDI）
             ,xca.edi_district_code       addon_edi_district_code     --顧客追加情報・EDI地区コード（EDI）
             ,xwcbr.edi_district_name     edi_district_name           --EDI地区名（EDI）
             ,xca.edi_district_name       addon_edi_district_name     --顧客追加情報・EDI地区名（EDI）
             ,xwcbr.edi_district_kana     edi_district_kana           --EDI地区名カナ（EDI）
             ,xca.edi_district_kana       addon_edi_district_kana     --顧客追加情報・EDI地区名カナ（EDI）
             ,xwcbr.tsukagatazaiko_div    tsukagatazaiko_div          --通過在庫型区分（EDI）
             ,xca.tsukagatazaiko_div      addon_tsukagatazaiko_div    --顧客追加情報・通過在庫型区分（EDI）
             ,xwcbr.deli_center_code      deli_center_code            --EDI納品センターコード
             ,xca.deli_center_code        addon_deli_center_code      --顧客追加情報・EDI納品センターコード
             ,xwcbr.deli_center_name      deli_center_name            --EDI納品センター名
             ,xca.deli_center_name        addon_deli_center_name      --顧客追加情報・EDI納品センター名
             ,xwcbr.edi_forward_number    edi_forward_number          --EDI伝送追番
             ,xca.edi_forward_number      addon_edi_forward_number    --顧客追加情報・EDI伝送追番
             ,xwcbr.cust_store_name       cust_store_name             --顧客店舗名称
             ,xca.cust_store_name         addon_cust_store_name       --顧客追加情報・顧客店舗名称
             ,xwcbr.torihikisaki_code     torihikisaki_code           --取引先コード
             ,xca.torihikisaki_code       addon_torihikisaki_code     --顧客追加情報・取引先コード
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
             ,xwcbr.vist_target_div       vist_target_div             --訪問対象区分
             ,xca.vist_target_div         addon_vist_target_div       --顧客追加情報・訪問対象区分
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
             ,xwcbr.intro_chain_code1      intro_chain_code1         --紹介者チェーンコード１
             ,xca.intro_chain_code1        addon_intro_chain_code1   --顧客追加情報・紹介者チェーンコード１
             ,xwcbr.intro_chain_code2      intro_chain_code2         --控除用チェーンコード
             ,xca.intro_chain_code2        addon_intro_chain_code2   --顧客追加情報・控除用チェーンコード
             ,xwcbr.sales_head_base_code   sales_head_base_code      --販売先本部担当拠点
             ,xca.sales_head_base_code     addon_sales_head_base_code  --顧客追加情報・販売先本部担当拠点
             ,xwcbr.cnvs_base_code         cnvs_base_code            --獲得拠点コード
             ,xca.cnvs_base_code           addon_cnvs_base_code      --顧客追加情報・獲得拠点コード
             ,xwcbr.cnvs_business_person   cnvs_business_person      --獲得営業員
             ,xca.cnvs_business_person     addon_cnvs_business_person  --顧客追加情報・獲得営業員
             ,xwcbr.new_point_div          new_point_div             --新規ポイント区分
             ,xca.new_point_div            addon_new_point_div       --顧客追加情報・新規ポイント区分
             ,xwcbr.new_point              new_point                 --新規ポイント
             ,xca.new_point                addon_new_point           --顧客追加情報・新規ポイント
             ,xwcbr.intro_base_code        intro_base_code           --紹介拠点コード
             ,xca.intro_base_code          addon_intro_base_code     --顧客追加情報・紹介拠点コード
             ,xwcbr.intro_business_person  intro_business_person     --紹介営業員
             ,xca.intro_business_person    addon_intro_business_person  --顧客追加情報・紹介営業員
             ,xwcbr.tdb_code               tdb_code                  --TDBコード
             ,xmc.tdb_code                 addon_tdb_code            --顧客法人情報・TDBコード
             ,xwcbr.corp_approval_date     corp_approval_date        --決裁日付
             ,xmc.approval_date            addon_corp_approval_date  --顧客法人情報・決裁日付
             ,xwcbr.base_code              base_code                 --本部担当拠点
             ,xmc.base_code                addon_base_code           --顧客法人情報・本部担当拠点
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
             ,xwcbr.address_lines_phonetic address_lines_phonetic    --電話番号
             ,xwcbr.address4               address4                  --FAX
             ,xwcbr.tax_div                tax_div                   --消費税区分
             ,xca.tax_div                  addon_tax_div             --顧客追加情報.消費税区分
             ,xwcbr.sale_base_code         sale_base_code            --売上拠点
             ,xca.sale_base_code           addon_sale_base_code      --顧客追加情報.売上拠点
             ,xwcbr.longitude              longitude                 --ピークカット開始時刻
             ,xca.longitude                addon_longitude           --顧客追加情報.ピークカット開始時刻
             ,xwcbr.calendar_code          calendar_code             --稼働日カレンダ
             ,xca.calendar_code            addon_calendar_code       --顧客追加情報.稼働日カレンダ
             ,xwcbr.rate                   rate                      --消化計算用掛率
             ,xca.rate                     addon_rate                --顧客追加情報.消化計算用掛率
             ,xwcbr.receiv_discount_rate   rcv_dsct_rate             --入金値引率
             ,xca.receiv_discount_rate     addon_rcv_dsct_rate       --顧客追加情報.入金値引率
             ,xwcbr.conclusion_day1        conclusion_day1           --消化計算締め日1
             ,xca.conclusion_day1          addon_conclusion_day1     --顧客追加情報・消化計算締め日1
             ,xwcbr.conclusion_day2        conclusion_day2           --消化計算締め日2
             ,xca.conclusion_day2          addon_conclusion_day2     --顧客追加情報・消化計算締め日2
             ,xwcbr.conclusion_day3        conclusion_day3           --消化計算締め日3
             ,xca.conclusion_day3          addon_conclusion_day3     --顧客追加情報・消化計算締め日3
             ,xwcbr.store_cust_code        store_cust_code           --店舗営業用顧客コード
             ,xca.store_cust_code          addon_store_cust_code     --顧客追加情報.店舗営業用顧客コード
-- Ver1.10 add end
-- Ver1.14 add start
             ,xwcbr.esm_target_div         esm_target_div            --ストレポ＆商談くん連携対象フラグ
             ,xca.esm_target_div           addon_esm_target_div      --顧客追加情報.ストレポ＆商談くん連携対象フラグ
-- Ver1.14 add end
-- Ver1.16 add start
             ,xwcbr.offset_cust_code       offset_cust_code          --相殺用顧客コード
             ,xca.offset_cust_code         addon_offset_cust_code    --顧客追加情報.相殺用顧客コード
             ,xwcbr.bp_customer_code       bp_customer_code          --取引先顧客コード
             ,xca.bp_customer_code         addon_bp_customer_code    --顧客追加情報.取引先顧客コード
-- Ver1.16 add end
-- Ver1.19 add start
             ,xwcbr.latitude               latitude                  --カテゴリー商品計上区分
             ,xca.latitude                 addon_latitude            --顧客追加情報.カテゴリー商品計上区分
-- Ver1.19 add end
-- Ver1.28 add start
             ,xwcbr.pos_enterprise_code    pos_enterprise_code       --POS企業コード
             ,xca.pos_enterprise_code      addon_pos_enterprise_code --顧客追加情報.POS企業コード
             ,xwcbr.pos_store_code         pos_store_code            --POS企業コード
             ,xca.pos_store_code           addon_pos_store_code      --顧客追加情報.POS企業コード
-- Ver1.28 add end
      FROM    hz_cust_accounts     hca,
              hz_cust_acct_sites   hcas,
              hz_cust_site_uses    hcsu,
              hz_parties           hp,
              hz_party_sites       hps,
              hz_locations         hl,
              xxcmm_cust_accounts  xca,
              xxcmm_mst_corporate  xmc,
              xxcmm_wk_cust_batch_regist xwcbr
      WHERE   hca.cust_account_id       = hcas.cust_account_id
      AND     hcas.cust_acct_site_id    = hcsu.cust_acct_site_id
      AND     ((hcsu.site_use_code      = cv_bill_to
              AND hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage))
-- 2017/10/18 Ver1.17 E_本稼動_14667 add start by Y.Omuro
      OR      (hcsu.site_use_code       = cv_bill_to
              AND hca.customer_class_code IS NULL)
-- 2017/10/18 Ver1.17 E_本稼動_14667 add end by Y.Omuro
      OR      (hcsu.site_use_code       = cv_other_to
              AND hca.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)))
      AND     hca.party_id              = hp.party_id
      AND     hp.party_id               = hps.party_id
      AND     hps.location_id           = hl.location_id
      AND     xca.customer_id           = hca.cust_account_id
      AND     xmc.customer_id (+)       = hca.cust_account_id
      AND     hcas.org_id = gv_org_id
      AND     hcsu.org_id = gv_org_id
      AND     hcas.party_site_id        = hps.party_site_id
      AND     hps.location_id           = (SELECT MIN(hpsiv.location_id)
                                           FROM   hz_cust_acct_sites hcasiv,
                                                  hz_party_sites     hpsiv
                                           WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                           AND    hcasiv.party_site_id   = hpsiv.party_site_id)
      AND     hca.account_number        = xwcbr.customer_code
-- 2010/01/27 Ver1.4 E_本稼動_01280 add start by Yutaka.Kuboshima
      AND     hcsu.status               = cv_a_flag
-- 2010/01/27 Ver1.4 E_本稼動_01280 add end by Yutaka.Kuboshima
      AND     xwcbr.file_id             = in_file_id_wk
      FOR UPDATE NOWAIT
      ;
    -- 支払条件取得カーソル
    CURSOR get_payment_term_cur(
      iv_payment_term IN VARCHAR2)
    IS
      SELECT rt.term_id  payment_term_id
      FROM   ra_terms    rt
      WHERE  rt.name   = iv_payment_term
      AND    ROWNUM    = 1
      ;
    -- 支払条件チェックカーソルレコード型
    get_payment_term_rec  get_payment_term_cur%ROWTYPE;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- 顧客使用目的マスタ出荷先レコードロックカーソル
    CURSOR get_rock_hcsu_ship_cur(
      in_cust_acct_site_id IN NUMBER)
    IS
      SELECT hcsu.site_use_id           site_use_id
            ,hcsu.cust_acct_site_id     cust_acct_site_id
            ,hcsu.object_version_number object_version_number
            ,hcsu.price_list_id         price_list_id
      FROM   hz_cust_site_uses hcsu
      WHERE  hcsu.site_use_code     = cv_ship_to
-- 2010/01/27 Ver1.4 E_本稼動_01280 add start by Yutaka.Kuboshima
      AND     hcsu.status           = cv_a_flag
-- 2010/01/27 Ver1.4 E_本稼動_01280 add end by Yutaka.Kuboshima
      AND    hcsu.cust_acct_site_id = in_cust_acct_site_id
      ;
    -- 顧客使用目的マスタ出荷先レコードロックカーソルレコード型
    get_rock_hcsu_ship_rec  get_rock_hcsu_ship_cur%ROWTYPE;
--
    -- 価格表取得カーソル
    CURSOR get_price_list_cur(
      iv_price_list IN VARCHAR2)
    IS
      SELECT qlhb.list_header_id list_header_id
      FROM   qp_list_headers_tl  qlht
            ,qp_list_headers_b   qlhb
      WHERE  qlht.list_header_id    = qlhb.list_header_id
      AND    qlht.source_lang       = cv_language_ja
      AND    qlht.language          = cv_language_ja
      AND    qlhb.orig_org_id       = fnd_global.org_id
      AND    qlhb.list_type_code    = cv_list_type_prl
      AND    gd_process_date BETWEEN NVL(qlhb.start_date_active, gd_process_date)
                                 AND NVL(qlhb.end_date_active, gd_process_date)
      AND    qlht.name              = iv_price_list
      ;
    -- 価格表チェックレコード型
    get_price_list_rec  get_price_list_cur%ROWTYPE;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- Ver1.14 add start
    -- eSM対象顧客区分チェックカーソル
    CURSOR check_esm_cust_class_cur(
      iv_cust_class IN VARCHAR2
    )
    IS
      SELECT flvv.lookup_code  AS esm_cust_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type  = cv_lkp_esm_cust_class
      AND    flvv.lookup_code  = iv_cust_class
      AND    flvv.enabled_flag = cv_yes
      ;
    -- eSM対象顧客区分チェックカーソルレコード型
    check_esm_cust_class_rec  check_esm_cust_class_cur%ROWTYPE;
-- Ver1.14 add end
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
    --顧客一括更新情報カーソルオープン
    << cust_data_loop >>
    FOR cust_data_rec IN cust_data_cur( in_file_id )
    LOOP
-- Ver1.14 add start
      -- ===============================
      -- ローカル変数の初期化
      -- ===============================
      lv_esm_cust_class   := NULL;         --eSM対象顧客区分確認用変数
-- Ver1.14 add end
      -- ===============================
      -- 顧客マスタ更新
      -- ===============================
      --顧客マスタ更新値設定
      p_cust_account_rec.cust_account_id  := cust_data_rec.customer_id;
      IF (cust_data_rec.customer_name_ryaku = cv_null_bar) THEN
        p_cust_account_rec.account_name   := CHR(0);                             --略称(NULL)
      ELSE
        p_cust_account_rec.account_name   := cust_data_rec.customer_name_ryaku;  --略称
      END IF;
      --顧客ステータスが「中止決裁済」のとき、顧客マスタの有効フラグを無効にする
      IF (cust_data_rec.customer_status = cv_stop_approved) THEN
        p_cust_account_rec.status         := cv_ignore;                          --顧客ステータス無効
      END IF;
      ln_cust_object_version_number       := cust_data_rec.cust_ovn;
      --顧客マスタ更新API呼び出し
      hz_cust_account_v2pub.update_cust_account(
                                          cv_init_list_api,
                                          p_cust_account_rec,
                                          ln_cust_object_version_number,
                                          lv_return_status,
                                          ln_msg_count,
                                          lv_msg_data);
      --顧客マスタ更新エラー時、RAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_cust_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_cust_err_expt;
      END IF;
      --変数初期化
      p_cust_account_rec.account_name  := NULL;
      p_cust_account_rec.status        := NULL;
      ln_cust_object_version_number    := NULL;
--
      -- ===============================
      -- パーティマスタ更新
      -- ===============================
      --パーティマスタ更新値設定
      ln_party_id            := cust_data_rec.party_id;
      lv_content_source_type := cv_user_entered;
      ln_party_object_version_number := cust_data_rec.party_ovn;
      --組織情報取得API
      hz_party_v2pub.get_organization_rec(
                                         cv_init_list_api,
                                         ln_party_id,
                                         lv_content_source_type,
                                         p_organization_rec,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --パーティ情報取得API
      hz_party_v2pub.get_party_rec(
                                         cv_init_list_api,
                                         ln_party_id,
                                         p_party_rec,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --パーティ情報更新値設定
      p_organization_rec.organization_name            := cust_data_rec.customer_name;       --顧客名称
      IF (cust_data_rec.customer_name_kana = cv_null_bar) THEN
        p_organization_rec.organization_name_phonetic := CHR(0);                            --顧客名称カナ(NULL)
      ELSE
        p_organization_rec.organization_name_phonetic := cust_data_rec.customer_name_kana;  --顧客名称カナ
      END IF;
      p_organization_rec.duns_number_c                := cust_data_rec.customer_status;     --顧客ステータス
      p_organization_rec.party_rec                    := p_party_rec;
      --パーティマスタ更新API呼び出し
      hz_party_v2pub.update_organization(
                                         cv_init_list_api,
                                         p_organization_rec,
                                         ln_party_object_version_number,
                                         ln_profile_id,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --パーティマスタ更新エラー時、RAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_party_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_party_err_expt;
      END IF;
      --変数初期化
      p_organization_rec.organization_name           := NULL;
      p_organization_rec.organization_name_phonetic  := NULL;
      p_organization_rec.duns_number_c               := NULL;
      p_organization_rec.party_rec                   := NULL;
      ln_party_object_version_number                 := NULL;
--
      -- ===============================
      -- 顧客使用目的更新
      -- ===============================
      --顧客区分'10'(顧客)、'12'(上様顧客)、'14'(売掛管理先顧客)のときのみ、顧客使用目的更新
      IF (cust_data_rec.customer_class_code   = cv_customer)
        OR (cust_data_rec.customer_class_code = cv_su_customer)
        OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
        --支払条件取得
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_id )
        LOOP
          ln_payment_term_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --第2支払条件取得
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_second )
        LOOP
          ln_payment_term_second_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --第3支払条件取得
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_third )
        LOOP
          ln_payment_term_third_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --顧客使用目的更新値設定
        p_cust_site_use_rec.site_use_id          := cust_data_rec.site_use_id;
        p_cust_site_use_rec.bill_to_site_use_id  := cust_data_rec.bill_to_site_use_id;
        IF (cust_data_rec.ar_invoice_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute4 := CHR(0);                          --売掛コード１（請求書）(NULL)
        ELSE
          p_cust_site_use_rec.attribute4 := cust_data_rec.ar_invoice_code;   --売掛コード１（請求書）
        END IF;
        IF (cust_data_rec.ar_location_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute5 := CHR(0);                          --売掛コード２（事業所）(NULL)
        ELSE
          p_cust_site_use_rec.attribute5 := cust_data_rec.ar_location_code;  --売掛コード２（事業所）
        END IF;
        IF (cust_data_rec.ar_others_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute6 := CHR(0);                          --売掛コード３（その他）(NULL)
        ELSE
          p_cust_site_use_rec.attribute6 := cust_data_rec.ar_others_code;    --売掛コード３（その他）
        END IF;
-- 2009/10/23 Ver1.2 delete start by Yutaka.Kuboshima
--       p_cust_site_use_rec.attribute1   := cust_data_rec.invoice_class;     --請求書発行区分
-- 2009/10/23 Ver1.2 delete end by Yutaka.Kuboshima
        IF (cust_data_rec.invoice_cycle = cv_null_bar) THEN
          p_cust_site_use_rec.attribute8 := CHR(0);                          --請求書発行サイクル(NULL)
        ELSE
          p_cust_site_use_rec.attribute8 := cust_data_rec.invoice_cycle;     --請求書発行サイクル
        END IF;
        IF (cust_data_rec.invoice_form = cv_null_bar) THEN
          p_cust_site_use_rec.attribute7 := CHR(0);                          --請求書出力形式(NULL)
        ELSE
          p_cust_site_use_rec.attribute7 := cust_data_rec.invoice_form;      --請求書出力形式
        END IF;
        p_cust_site_use_rec.payment_term_id := ln_payment_term_id;           --支払条件
        IF (cust_data_rec.payment_term_second = cv_null_bar) THEN
          p_cust_site_use_rec.attribute2 := CHR(0);                          --第2支払条件(NULL)
        ELSE
          p_cust_site_use_rec.attribute2 := ln_payment_term_second_id;       --第2支払条件
        END IF;
        IF (cust_data_rec.payment_term_third = cv_null_bar) THEN
          p_cust_site_use_rec.attribute3 := CHR(0);                          --第3支払条件(NULL)
        ELSE
          p_cust_site_use_rec.attribute3 := ln_payment_term_third_id;        --第3支払条件
        END IF;
        ln_csu_object_version_number     := cust_data_rec.site_use_ovn;      --顧客使用目的オブジェクト世代番号
        --顧客使用目的マスタ更新API呼び出し
        hz_cust_account_site_v2pub.update_cust_site_use(
                                            cv_init_list_api,
                                            p_cust_site_use_rec,
                                            ln_csu_object_version_number,
                                            lv_return_status,
                                            ln_msg_count,
                                            lv_msg_data);
        --顧客使用目的マスタ更新エラー時、RAISE
        IF lv_return_status <> cv_success_api THEN
          gv_out_msg  := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcmm_msg_kbn
                           ,iv_name         => cv_update_csu_err_msg
                           ,iv_token_name1  => cv_cust_code
                           ,iv_token_value1 => cust_data_rec.customer_number
                          );
          lv_errmsg := gv_out_msg;
          lv_errbuf := lv_msg_data;
          RAISE update_csu_err_expt;
        END IF;
        --変数初期化
        p_cust_site_use_rec.site_use_id          := NULL;
        p_cust_site_use_rec.bill_to_site_use_id  := NULL;
        p_cust_site_use_rec.attribute4           := NULL;
        p_cust_site_use_rec.attribute5           := NULL;
        p_cust_site_use_rec.attribute6           := NULL;
        p_cust_site_use_rec.attribute1           := NULL;
        p_cust_site_use_rec.attribute8           := NULL;
        p_cust_site_use_rec.attribute7           := NULL;
        p_cust_site_use_rec.payment_term_id      := NULL;
        p_cust_site_use_rec.attribute2           := NULL;
        p_cust_site_use_rec.attribute3           := NULL;
        ln_csu_object_version_number             := NULL;
        ln_payment_term_id                       := NULL;
        ln_payment_term_second_id                := NULL;
        ln_payment_term_third_id                 := NULL;
      END IF;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
      -- 顧客使用目的マスタ出荷先レコード更新
      -- 顧客区分'10'(顧客)、'12'(上様顧客)のとき、出荷先レコード更新
      IF (cust_data_rec.customer_class_code IN (cv_customer, cv_su_customer)) THEN
        -- 顧客使用目的マスタ出荷先レコードロック
        << get_rock_hcsu_ship_loop >>
        FOR get_rock_hcsu_ship_rec IN get_rock_hcsu_ship_cur( cust_data_rec.cust_acct_site_id )
        LOOP
          -- 価格表設定
          -- 価格表が'-'の場合
          IF (cust_data_rec.price_list = cv_null_bar) THEN
            -- FND_API.G_MISS_NUMをセット(価格表をNULLに設定するため)
            ln_price_list := FND_API.G_MISS_NUM;
          ELSIF (cust_data_rec.price_list IS NULL) THEN
            -- 更新前の値をセット
            ln_price_list := get_rock_hcsu_ship_rec.price_list_id;
          ELSE
            -- CSVの項目値から価格表を取得
            << get_price_list_loop >>
            FOR get_price_list_rec IN get_price_list_cur( cust_data_rec.price_list )
            LOOP
              ln_price_list := get_price_list_rec.list_header_id;
            END LOOP get_price_list_loop;
          END IF;
          -- 更新項目設定
          p_cust_site_use_ship_rec.site_use_id       := get_rock_hcsu_ship_rec.site_use_id;           --顧客使用目的ID
          p_cust_site_use_ship_rec.cust_acct_site_id := get_rock_hcsu_ship_rec.cust_acct_site_id;     --顧客所在地ID
          p_cust_site_use_ship_rec.site_use_code     := cv_ship_to;                                   --使用目的コード
          p_cust_site_use_ship_rec.price_list_id     := ln_price_list;                                --価格表
          ln_csu_ship_object_number                  := get_rock_hcsu_ship_rec.object_version_number; --顧客使用目的オブジェクト世代番号
          --顧客使用目的マスタ更新API呼び出し
          hz_cust_account_site_v2pub.update_cust_site_use(
                                              cv_init_list_api,
                                              p_cust_site_use_ship_rec,
                                              ln_csu_ship_object_number,
                                              lv_return_status,
                                              ln_msg_count,
                                              lv_msg_data);
          --顧客使用目的マスタ更新エラー時、RAISE
          IF lv_return_status <> cv_success_api THEN
            gv_out_msg  := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcmm_msg_kbn
                             ,iv_name         => cv_update_csu_err_msg
                             ,iv_token_name1  => cv_cust_code
                             ,iv_token_value1 => cust_data_rec.customer_number
                            );
            lv_errmsg := gv_out_msg;
            lv_errbuf := lv_msg_data;
            RAISE update_csu_err_expt;
          END IF;
        END LOOP get_rock_hcsu_ship_loop;
        -- 変数初期化
        p_cust_site_use_ship_rec  := NULL;
        ln_csu_ship_object_number := NULL;
        ln_price_list             := NULL;
      END IF;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
      --
      -- ===============================
      -- 顧客事業所更新
      -- ===============================
      p_location_rec.location_id        := cust_data_rec.location_id;
      p_location_rec.postal_code        := cust_data_rec.postal_code;   --郵便番号
      p_location_rec.state              := cust_data_rec.state;         --都道府県
      p_location_rec.city               := cust_data_rec.city;          --市・区
      p_location_rec.address1           := cust_data_rec.address1;      --住所1
      IF (cust_data_rec.address2 = cv_null_bar) THEN
        p_location_rec.address2         := CHR(0);                      --住所2(NULL)
      ELSE
        p_location_rec.address2         := cust_data_rec.address2;      --住所2
      END IF;
      p_location_rec.address3           := cust_data_rec.address3;      --地区コード
-- Ver1.10 add start
      p_location_rec.address_lines_phonetic
                                        := cust_data_rec.address_lines_phonetic;
                                                                        --電話番号
      IF (cust_data_rec.address4 = cv_null_bar)
      THEN
        p_location_rec.address4         := CHR(0);
      ELSE
        p_location_rec.address4         := cust_data_rec.address4;      --FAX
      END IF;
-- Ver1.10 add end
      ln_location_object_version_num    := cust_data_rec.location_ovn;
      --顧客事業所マスタ更新API呼び出し
      hz_location_v2pub.update_location(
                                          cv_init_list_api,
                                          p_location_rec,
                                          ln_location_object_version_num,
                                          lv_return_status,
                                          ln_msg_count,
                                          lv_msg_data);
      --顧客事業所マスタ更新エラー時、RAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_location_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_location_err_expt;
      END IF;
      --変数初期化
      p_location_rec.location_id        := NULL;
      p_location_rec.postal_code        := NULL;
      p_location_rec.state              := NULL;
      p_location_rec.city               := NULL;
      p_location_rec.address1           := NULL;
      p_location_rec.address2           := NULL;
      p_location_rec.address3           := NULL;
-- Ver1.10 add start
      p_location_rec.address_lines_phonetic
                                        := NULL;  -- 電話番号
      p_location_rec.address4           := NULL;  -- FAX
-- Ver1.10 add end
      ln_location_object_version_num    := NULL;
--
    -- ===============================
    -- 顧客追加情報更新
    -- ===============================
-- 2009/10/23 modify start by Yutaka.Kuboshima
--    --顧客区分が'10'(顧客)、'14'(売掛管理先顧客)のときのみ、チェーン店コード（販売先）・チェーン店コード（納品先）・
--    --チェーン店コード（営業政策用）・チェーン店コード（ＥＤＩ）・店舗コードを更新
--    IF   (cust_data_rec.customer_class_code = cv_customer)
--      OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
--      UPDATE xxcmm_cust_accounts xca
--      SET    xca.stop_approval_reason   = DECODE(cust_data_rec.approval_reason,            --中止理由
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_reason,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.approval_reason),
--             xca.stop_approval_date     = DECODE(cust_data_rec.approval_date,              --中止決済日
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_date,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 TO_DATE(cust_data_rec.approval_date,
--                                                         cv_date_format)),
--             xca.sales_chain_code       = DECODE(cust_data_rec.sales_chain_code,           --チェーン店コード（販売先）
--                                                 NULL,
--                                                 cust_data_rec.addon_sales_chain_code,
--                                                 cust_data_rec.sales_chain_code),
--             xca.delivery_chain_code    = DECODE(cust_data_rec.delivery_chain_code,        --チェーン店コード（納品先）
--                                                 NULL,
--                                                 cust_data_rec.addon_delivery_chain_code,
--                                                 cust_data_rec.delivery_chain_code),
--             xca.policy_chain_code      = DECODE(cust_data_rec.policy_chain_code,          --チェーン店コード（営業政策用）
--                                                 NULL,
--                                                 cust_data_rec.addon_policy_chain_code,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.policy_chain_code),
--             xca.chain_store_code       = DECODE(cust_data_rec.chain_store_code,           --チェーン店コード（ＥＤＩ）
--                                                 NULL,
--                                                 cust_data_rec.addon_chain_store_code,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.chain_store_code),
--             xca.store_code             = DECODE(cust_data_rec.store_code,                 --店舗コード
--                                                 NULL,
--                                                 cust_data_rec.addon_store_code,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.store_code),
--             xca.business_low_type      = DECODE(cust_data_rec.business_low_type,          --業態（小分類）
--                                                 NULL,
--                                                 cust_data_rec.addon_business_low_type,
--                                                 cust_data_rec.business_low_type),
--             xca.last_updated_by        = fnd_global.user_id,                              --最終更新者
--             xca.last_update_date       = sysdate,                                         --最終更新日
--             xca.request_id             = fnd_profile.value(cv_conc_request_id),           --要求ID
--             xca.program_application_id = fnd_profile.value(cv_prog_appl_id),              --コンカレント・プログラム･アプリケーションID
--             xca.program_id             = fnd_profile.value(cv_conc_program_id),           --コンカレント・プログラムID
--             xca.program_update_date    = sysdate                                          --プログラム更新日
--      WHERE  xca.customer_id = cust_data_rec.customer_id
--      ;
--    --それ以外の場合、チェーン店コード（販売先）・チェーン店コード（納品先）・チェーン店コード（営業政策用）・
--    --チェーン店コード（ＥＤＩ）・店舗コードは更新しない
--    ELSE
--      UPDATE xxcmm_cust_accounts xca
--      SET    xca.stop_approval_reason   = DECODE(cust_data_rec.approval_reason,            --中止理由
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_reason,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.approval_reason),
--             xca.stop_approval_date     = DECODE(cust_data_rec.approval_date,              --中止決済日
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_date,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 TO_DATE(cust_data_rec.approval_date,
--                                                         cv_date_format)),
--             xca.business_low_type      = DECODE(cust_data_rec.business_low_type,          --業態（小分類）
--                                                 NULL,
--                                                 cust_data_rec.addon_business_low_type,
--                                                 cust_data_rec.business_low_type),
--             xca.last_updated_by        = fnd_global.user_id,                              --最終更新者
--             xca.last_update_date       = sysdate,                                         --最終更新日
--             xca.request_id             = fnd_profile.value(cv_conc_request_id),           --要求ID
--             xca.program_application_id = fnd_profile.value(cv_prog_appl_id),              --コンカレント・プログラム･アプリケーションID
--             xca.program_id             = fnd_profile.value(cv_conc_program_id),           --コンカレント・プログラムID
--             xca.program_update_date    = sysdate                                          --プログラム更新日
--      WHERE  xca.customer_id = cust_data_rec.customer_id
--      ;
--    END IF;
--
    -- ===============================
    -- 顧客追加情報マスタ更新項目設定
    -- ===============================
    --
    -- ===============================
    -- 中止理由
    -- ===============================
    -- 中止理由が'-'の場合
    IF (cust_data_rec.approval_reason = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.stop_approval_reason := NULL;
    -- 中止理由がNULLの場合
    ELSIF (cust_data_rec.approval_reason IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.stop_approval_reason := cust_data_rec.addon_approval_reason;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.stop_approval_reason := cust_data_rec.approval_reason;
    END IF;
    --
    -- ===============================
    -- 中止決済日
    -- ===============================
    -- 中止決済日が'-'の場合
    IF (cust_data_rec.approval_date = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.stop_approval_date := NULL;
    -- 中止決済日がNULLの場合
    ELSIF (cust_data_rec.approval_date IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.stop_approval_date := cust_data_rec.addon_approval_date;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.stop_approval_date := TO_DATE(cust_data_rec.approval_date, cv_date_format);
    END IF;
    --
    -- ===============================
    -- チェーン店コード（販売先）
    -- ===============================
    -- チェーン店コード（販売先）がNULLまたは、
    -- 顧客区分が'10','12','14','15','16'以外の場合
    IF (cust_data_rec.sales_chain_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.sales_chain_code := cust_data_rec.addon_sales_chain_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.sales_chain_code := cust_data_rec.sales_chain_code;
    END IF;
    --
    -- ===============================
    -- チェーン店コード（納品先）
    -- ===============================
    -- チェーン店コード（納品先）がNULLまたは、
    -- 顧客区分が'10','12','14','15','16'以外の場合
    IF (cust_data_rec.delivery_chain_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.delivery_chain_code := cust_data_rec.addon_delivery_chain_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.delivery_chain_code := cust_data_rec.delivery_chain_code;
    END IF;
    --
    -- ===============================
    -- チェーン店コード（営業政策用）
    -- ===============================
    -- チェーン店コード（営業政策用）が'-'の場合
    IF (cust_data_rec.policy_chain_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.policy_chain_code := NULL;
    -- チェーン店コード（営業政策用）がNULLまたは、
    -- 顧客区分が'10','14'以外の場合
    ELSIF (cust_data_rec.policy_chain_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_urikake_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.policy_chain_code := cust_data_rec.addon_policy_chain_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.policy_chain_code := cust_data_rec.policy_chain_code;
    END IF;
    --
    -- ===============================
    -- チェーン店コード（ＥＤＩ）
    -- ===============================
    -- チェーン店コード（ＥＤＩ）が'-'の場合
    IF (cust_data_rec.chain_store_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.chain_store_code := NULL;
    -- チェーン店コード（ＥＤＩ）がNULLまたは、
    -- 顧客区分が'10','14'以外の場合
    ELSIF (cust_data_rec.chain_store_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_urikake_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.chain_store_code := cust_data_rec.addon_chain_store_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.chain_store_code := cust_data_rec.chain_store_code;
    END IF;
    --
    -- ===============================
    -- 店舗コード
    -- ===============================
    -- 店舗コードが'-'の場合
    IF (cust_data_rec.store_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.store_code := NULL;
    -- 店舗コードがNULLまたは、
    -- 顧客区分が'10','14','20','21'以外の場合
    ELSIF (cust_data_rec.store_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_urikake_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.store_code := cust_data_rec.addon_store_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.store_code := cust_data_rec.store_code;
    END IF;
    --
    -- ===============================
    -- 業態（小分類）
    -- ===============================
    -- 業態（小分類）が'-'の場合
    IF (cust_data_rec.business_low_type = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.business_low_type := NULL;
    -- 業態（小分類）がNULLまたは、
    -- 顧客区分が'18','19','20','21'の場合
    ELSIF (cust_data_rec.business_low_type IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.business_low_type := cust_data_rec.addon_business_low_type;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.business_low_type := cust_data_rec.business_low_type;
    END IF;
    --
    -- ===============================
    -- 請求書印刷単位
    -- ===============================
    -- 請求書印刷単位がNULLまたは、
    -- 顧客区分が'10'以外の場合
    IF (cust_data_rec.invoice_class IS NULL)
      OR (cust_data_rec.customer_class_code <> cv_kokyaku_kbn)
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.invoice_printing_unit := cust_data_rec.addon_invoice_class;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.invoice_printing_unit := cust_data_rec.invoice_class;
    END IF;
    --
    -- ===============================
    -- 請求書用コード
    -- ===============================
    -- 請求書用コードが'-'の場合
    IF (cust_data_rec.invoice_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.invoice_code := NULL;
    -- 請求書用コードがNULLまたは、
    -- 顧客区分が'10'以外の場合
    ELSIF (cust_data_rec.invoice_code IS NULL)
      OR (cust_data_rec.customer_class_code <> cv_kokyaku_kbn)
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.invoice_code := cust_data_rec.addon_invoice_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.invoice_code := cust_data_rec.invoice_code;
    END IF;
    --
-- Ver1.27 add start
    -- ===============================
    -- 請求書消費税積上げ計算方式
    -- ===============================
    -- 請求書消費税積上げ計算方式がNULL以外（Y/N）、かつ、顧客区分が'10'(顧客)、'14'(売掛管理先)の場合、更新が可能
    IF cust_data_rec.invoice_tax_div IS NOT NULL and cust_data_rec.customer_class_code IN (cv_kokyaku_kbn, cv_urikake_kbn)
    THEN
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.invoice_tax_div := cust_data_rec.invoice_tax_div;
    ELSE
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.invoice_tax_div := cust_data_rec.addon_invoice_tax_div;
    END IF;
-- Ver1.27 add end
    --
    -- ===============================
    -- 業種
    -- ===============================
    -- 業種が'-'の場合
    IF (cust_data_rec.industry_div = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.industry_div := NULL;
    -- 業種がNULLまたは、
    -- 顧客区分が'18','19','20','21'の場合
    ELSIF (cust_data_rec.industry_div IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.industry_div := cust_data_rec.addon_industry_div;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.industry_div := cust_data_rec.industry_div;
    END IF;
    --
    -- ===============================
    -- 請求拠点
    -- ===============================
    -- 請求拠点がNULLまたは、
    -- 顧客区分が'10','12','14','20','21'以外の場合
    IF (cust_data_rec.bill_base_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.bill_base_code := cust_data_rec.addon_bill_base_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.bill_base_code := cust_data_rec.bill_base_code;
    END IF;
    --
    -- ===============================
    -- 入金拠点
    -- ===============================
    -- 入金拠点がNULLまたは、
    -- 顧客区分が'10','12','14'以外の場合
    IF (cust_data_rec.receiv_base_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.receiv_base_code := cust_data_rec.addon_receiv_base_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.receiv_base_code := cust_data_rec.receiv_base_code;
    END IF;
    --
    -- ===============================
    -- 納品拠点
    -- ===============================
    -- 納品拠点が'-'の場合
    IF (cust_data_rec.delivery_base_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.delivery_base_code := NULL;
    -- 納品拠点がNULLまたは、
    -- 顧客区分が'10','12','14'以外の場合
    ELSIF (cust_data_rec.delivery_base_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.delivery_base_code := cust_data_rec.addon_delivery_base_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.delivery_base_code := cust_data_rec.delivery_base_code;
    END IF;
    --
    -- ===============================
    -- 売上実績振替
    -- ===============================
    -- 売上実績振替が'-'の場合
    IF (cust_data_rec.selling_transfer_div = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.selling_transfer_div := NULL;
    -- 売上実績振替がNULLまたは、
    -- 顧客区分が'18','19','20','21'の場合
    ELSIF (cust_data_rec.selling_transfer_div IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.selling_transfer_div := cust_data_rec.addon_selling_transfer_div;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.selling_transfer_div := cust_data_rec.selling_transfer_div;
    END IF;
    --
    -- ===============================
    -- カード会社
    -- ===============================
    -- カード会社が'-'の場合
    IF (cust_data_rec.card_company = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.card_company := NULL;
    -- カード会社がNULLまたは、
    -- 顧客区分が'10'以外の場合
    ELSIF (cust_data_rec.card_company IS NULL)
      OR (cust_data_rec.customer_class_code <> cv_kokyaku_kbn)
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.card_company := cust_data_rec.addon_card_company;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.card_company := cust_data_rec.card_company;
    END IF;
    --
    -- ===============================
    -- 問屋管理コード
    -- ===============================
    -- 問屋管理コードが'-'の場合
    IF (cust_data_rec.wholesale_ctrl_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.wholesale_ctrl_code := NULL;
    -- 問屋管理コードがNULLまたは、
    -- 顧客区分が'18','19','20','21'の場合
    ELSIF (cust_data_rec.wholesale_ctrl_code IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.wholesale_ctrl_code := cust_data_rec.addon_wholesale_ctrl_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.wholesale_ctrl_code := cust_data_rec.wholesale_ctrl_code;
    END IF;
    --
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
    -- ===============================
    -- 前月顧客ステータス
    -- ===============================
    -- 中止決裁日が'-'の場合
    IF (NVL(cust_data_rec.approval_date, cv_null_bar) = cv_null_bar) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.past_customer_status := cust_data_rec.addon_past_customer_status;
    ELSE
      -- 中止決裁日が前月の場合
      IF (TRUNC(TO_DATE(cust_data_rec.approval_date, cv_date_format), 'MM') = ADD_MONTHS(TRUNC(gd_process_date, 'MM'), -1)) THEN
        -- '90'(中止決裁済)をセット
        l_xxcmm_cust_accounts.past_customer_status := cv_stop_approved;
      ELSE
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.past_customer_status := cust_data_rec.addon_past_customer_status;
      END IF;
    END IF;
    --
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
    --
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
    -- ===============================
    -- 出荷元保管場所
    -- ===============================
    -- 出荷元保管場所が'-'の場合
    IF (cust_data_rec.ship_storage_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.ship_storage_code := NULL;
    -- 出荷元保管場所がNULLまたは、
    -- 顧客区分が'18','19','20','21'の場合
    ELSIF (cust_data_rec.ship_storage_code IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.ship_storage_code := cust_data_rec.addon_ship_storage_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.ship_storage_code := cust_data_rec.ship_storage_code;
    END IF;
    --
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
    -- ===============================
    -- 配送順（EDI）
    -- ===============================
    -- 配送順（EDI）が'-'の場合
    IF (cust_data_rec.delivery_order = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.delivery_order := NULL;
    -- 配送順（EDI）がNULLの場合
    ELSIF (cust_data_rec.delivery_order IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.delivery_order := cust_data_rec.addon_delivery_order;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.delivery_order := cust_data_rec.delivery_order;
    END IF;
    --
    -- ===============================
    -- EDI地区コード（EDI）
    -- ===============================
    -- EDI地区コード（EDI）が'-'の場合
    IF (cust_data_rec.edi_district_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.edi_district_code := NULL;
    -- EDI地区コード（EDI）がNULLの場合
    ELSIF (cust_data_rec.edi_district_code IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.edi_district_code := cust_data_rec.addon_edi_district_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.edi_district_code := cust_data_rec.edi_district_code;
    END IF;
    --
    -- ===============================
    -- EDI地区名（EDI）
    -- ===============================
    -- EDI地区名（EDI）が'-'の場合
    IF (cust_data_rec.edi_district_name = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.edi_district_name := NULL;
    -- EDI地区名（EDI）がNULLの場合
    ELSIF (cust_data_rec.edi_district_name IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.edi_district_name := cust_data_rec.addon_edi_district_name;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.edi_district_name := cust_data_rec.edi_district_name;
    END IF;
    --
    -- ===============================
    -- EDI地区名カナ（EDI）
    -- ===============================
    -- EDI地区名カナ（EDI）が'-'の場合
    IF (cust_data_rec.edi_district_kana = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.edi_district_kana := NULL;
    -- EDI地区名カナ（EDI）がNULLの場合
    ELSIF (cust_data_rec.edi_district_kana IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.edi_district_kana := cust_data_rec.addon_edi_district_kana;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.edi_district_kana := cust_data_rec.edi_district_kana;
    END IF;
    --
    -- ===============================
    -- 通過在庫型区分（EDI）
    -- ===============================
    -- 通過在庫型区分（EDI）が'-'の場合
    IF (cust_data_rec.tsukagatazaiko_div = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.tsukagatazaiko_div := NULL;
    -- 通過在庫型区分（EDI）がNULLの場合
    ELSIF (cust_data_rec.tsukagatazaiko_div IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.tsukagatazaiko_div := cust_data_rec.addon_tsukagatazaiko_div;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.tsukagatazaiko_div := cust_data_rec.tsukagatazaiko_div;
    END IF;
    --
    -- ===============================
    -- EDI納品センターコード
    -- ===============================
    -- EDI納品センターコードが'-'の場合
    IF (cust_data_rec.deli_center_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.deli_center_code := NULL;
    -- EDI納品センターコードがNULLの場合
    ELSIF (cust_data_rec.deli_center_code IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.deli_center_code := cust_data_rec.addon_deli_center_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.deli_center_code := cust_data_rec.deli_center_code;
    END IF;
    --
    -- ===============================
    -- EDI納品センター名
    -- ===============================
    -- EDI納品センター名が'-'の場合
    IF (cust_data_rec.deli_center_name = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.deli_center_name := NULL;
    -- EDI納品センター名がNULLの場合
    ELSIF (cust_data_rec.deli_center_name IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.deli_center_name := cust_data_rec.addon_deli_center_name;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.deli_center_name := cust_data_rec.deli_center_name;
    END IF;
    --
    -- ===============================
    -- EDI伝送追番
    -- ===============================
    -- EDI伝送追番が'-'の場合
    IF (cust_data_rec.edi_forward_number = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.edi_forward_number := NULL;
    -- EDI伝送追番がNULLの場合
    ELSIF (cust_data_rec.edi_forward_number IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.edi_forward_number := cust_data_rec.addon_edi_forward_number;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.edi_forward_number := cust_data_rec.edi_forward_number;
    END IF;
    --
    -- ===============================
    -- 顧客店舗名称
    -- ===============================
    -- 顧客店舗名称が'-'の場合
    IF (cust_data_rec.cust_store_name = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.cust_store_name := NULL;
    -- 顧客店舗名称がNULLの場合
    ELSIF (cust_data_rec.cust_store_name IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.cust_store_name := cust_data_rec.addon_cust_store_name;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.cust_store_name := cust_data_rec.cust_store_name;
    END IF;
    --
    -- ===============================
    -- 取引先コード
    -- ===============================
    -- 取引先コードが'-'の場合
    IF (cust_data_rec.torihikisaki_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.torihikisaki_code := NULL;
    -- 取引先コードがNULLの場合
    ELSIF (cust_data_rec.torihikisaki_code IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.torihikisaki_code := cust_data_rec.addon_torihikisaki_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.torihikisaki_code := cust_data_rec.torihikisaki_code;
    END IF;
--
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
    -- ===============================
    -- 訪問対象区分
    -- ===============================
    -- 訪問対象区分が'-'の場合
    IF (cust_data_rec.vist_target_div = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.vist_target_div := NULL;
    -- 訪問対象区分がNULLの場合
    ELSIF (cust_data_rec.vist_target_div IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.vist_target_div := cust_data_rec.addon_vist_target_div;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.vist_target_div := cust_data_rec.vist_target_div;
    END IF;
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
    -- ===============================
    -- 紹介者チェーンコード１
    -- ===============================
    -- 紹介者チェーンコード１が'-'の場合
    IF (cust_data_rec.intro_chain_code1 = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.intro_chain_code1 := NULL;
    -- 紹介者チェーンコード１がNULLの場合
    ELSIF (cust_data_rec.intro_chain_code1 IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.intro_chain_code1 := cust_data_rec.addon_intro_chain_code1;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.intro_chain_code1 := cust_data_rec.intro_chain_code1;
    END IF;
--
    -- ===============================
    -- 控除用チェーンコード
    -- ===============================
    -- 控除用チェーンコードが'-'の場合
    IF (cust_data_rec.intro_chain_code2 = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.intro_chain_code2 := NULL;
    -- 控除用チェーンコードがNULLの場合
    ELSIF (cust_data_rec.intro_chain_code2 IS NULL) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.intro_chain_code2 := cust_data_rec.addon_intro_chain_code2;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.intro_chain_code2 := cust_data_rec.intro_chain_code2;
    END IF;
--
    -- ===============================
    -- 販売先本部担当拠点
    -- ===============================
    --顧客区分「10：顧客」「14：売掛管理先顧客」「19：百貨店伝区」の場合
    IF ( cust_data_rec.customer_class_code IN (cv_kokyaku_kbn, cv_urikake_kbn, cv_hyakkaten_kbn) ) THEN
      -- 販売先本部担当拠点が'-'の場合
      IF (cust_data_rec.sales_head_base_code = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.sales_head_base_code := NULL;
      -- 販売先本部担当拠点がNULLの場合
      ELSIF (cust_data_rec.sales_head_base_code IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.sales_head_base_code := cust_data_rec.addon_sales_head_base_code;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.sales_head_base_code := cust_data_rec.sales_head_base_code;
      END IF;
    --
    ELSE
    --顧客区分「10：顧客」「14：売掛管理先顧客」「19：百貨店伝区」以外の場合、設定不可
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.sales_head_base_code := cust_data_rec.addon_sales_head_base_code;
    --
    END IF;
--
    -- ===============================
    -- 獲得拠点コード
    -- ===============================
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- 獲得拠点コードが'-'の場合
      IF (cust_data_rec.cnvs_base_code = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.cnvs_base_code := NULL;
      -- 獲得拠点コードがNULLの場合
      ELSIF (cust_data_rec.cnvs_base_code IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.cnvs_base_code := cust_data_rec.addon_cnvs_base_code;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.cnvs_base_code := cust_data_rec.cnvs_base_code;
      END IF;
    --
    ELSE
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」以外の場合、設定不可
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.cnvs_base_code := cust_data_rec.addon_cnvs_base_code;
    --
    END IF;
--
    -- ===============================
    -- 獲得営業員
    -- ===============================
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- 獲得営業員が'-'の場合
      IF (cust_data_rec.cnvs_business_person = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.cnvs_business_person := NULL;
      -- 獲得営業員がNULLの場合
      ELSIF (cust_data_rec.cnvs_business_person IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.cnvs_business_person := cust_data_rec.addon_cnvs_business_person;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.cnvs_business_person := cust_data_rec.cnvs_business_person;
      END IF;
    --
    ELSE
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」以外の場合、設定不可
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.cnvs_business_person := cust_data_rec.addon_cnvs_business_person;
    --
    END IF;
--
    -- ===============================
    -- 新規ポイント区分
    -- ===============================
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- 新規ポイント区分が'-'の場合
      IF (cust_data_rec.new_point_div = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.new_point_div := NULL;
      -- 新規ポイント区分がNULLの場合
      ELSIF (cust_data_rec.new_point_div IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.new_point_div := cust_data_rec.addon_new_point_div;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.new_point_div := cust_data_rec.new_point_div;
      END IF;
    --
    ELSE
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」以外の場合、設定不可
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.new_point_div := cust_data_rec.addon_new_point_div;
    --
    END IF;
--
    -- ===============================
    -- 新規ポイント
    -- ===============================
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- 新規ポイントが'-'の場合
      IF (cust_data_rec.new_point = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.new_point := NULL;
      -- 新規ポイントがNULLの場合
      ELSIF (cust_data_rec.new_point IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.new_point := cust_data_rec.addon_new_point;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.new_point := TO_NUMBER(cust_data_rec.new_point, 999);
      END IF;
    --
    ELSE
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」以外の場合、設定不可
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.new_point := cust_data_rec.addon_new_point;
    --
    END IF;
--
    -- ===============================
    -- 紹介拠点コード
    -- ===============================
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- 紹介拠点コードが'-'の場合
      IF (cust_data_rec.intro_base_code = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.intro_base_code := NULL;
      -- 紹介拠点コードがNULLの場合
      ELSIF (cust_data_rec.intro_base_code IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.intro_base_code := cust_data_rec.addon_intro_base_code;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.intro_base_code := cust_data_rec.intro_base_code;
      END IF;
    ELSE
      --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」以外の場合、設定不可
      l_xxcmm_cust_accounts.intro_base_code := cust_data_rec.addon_intro_base_code;
    END IF;
--
    -- ===============================
    -- 紹介営業員
    -- ===============================
    --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- 紹介営業員が'-'の場合
      IF (cust_data_rec.intro_business_person = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_cust_accounts.intro_business_person := NULL;
      -- 紹介営業員がNULLの場合
      ELSIF (cust_data_rec.intro_business_person IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_cust_accounts.intro_business_person := cust_data_rec.addon_intro_business_person;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_cust_accounts.intro_business_person := cust_data_rec.intro_business_person;
      END IF;
    ELSE
      --顧客区分「10：顧客」「15：店舗営業」「17：計画立案用」以外の場合、設定不可
      l_xxcmm_cust_accounts.intro_business_person := cust_data_rec.addon_intro_business_person;
    END IF;
--
    -- ===============================
    -- TDBコード
    -- ===============================
    --顧客区分「13：法人顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_trust_corp ) THEN
      -- TDBコードが'-'の場合
      IF (cust_data_rec.tdb_code = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_mst_corporate.tdb_code := NULL;
      -- TDBコードがNULLの場合
      ELSIF (cust_data_rec.tdb_code IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_mst_corporate.tdb_code := cust_data_rec.addon_tdb_code;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_mst_corporate.tdb_code := cust_data_rec.tdb_code;
      END IF;
    ELSE
      --顧客区分「13：法人顧客」以外の場合、設定不可
      l_xxcmm_mst_corporate.tdb_code := cust_data_rec.addon_tdb_code;
    END IF;
--
    -- ===============================
    -- 決裁日付
    -- ===============================
    --顧客区分「13：法人顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_trust_corp ) THEN
      -- 決裁日付が'-'の場合
      IF (cust_data_rec.corp_approval_date = cv_null_bar) THEN
        -- NULLをセット
        l_xxcmm_mst_corporate.approval_date := NULL;
      -- 決裁日付がNULLの場合
      ELSIF (cust_data_rec.corp_approval_date IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_mst_corporate.approval_date := cust_data_rec.addon_corp_approval_date;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_mst_corporate.approval_date := TO_DATE(cust_data_rec.corp_approval_date, cv_date_format);
      END IF;
    ELSE
      --顧客区分「13：法人顧客」以外の場合、設定不可
      l_xxcmm_mst_corporate.approval_date := cust_data_rec.addon_corp_approval_date;
    END IF;
--
    -- ===============================
    -- 本部担当拠点
    -- ===============================
    --顧客区分「13：法人顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_trust_corp ) THEN
      -- 本部担当拠点がNULLの場合
      IF (cust_data_rec.base_code IS NULL) THEN
        -- 更新前の値をセット
        l_xxcmm_mst_corporate.base_code := cust_data_rec.addon_base_code;
      ELSE
        -- CSVの項目値をセット
        l_xxcmm_mst_corporate.base_code := cust_data_rec.base_code;
      END IF;
    ELSE
      --顧客区分「13：法人顧客」以外の場合、設定不可
      l_xxcmm_mst_corporate.base_code := cust_data_rec.addon_base_code;
    END IF;
--
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
    -- ===============================
    -- 消費税区分
    -- ===============================
    --顧客区分が'10'、'12'、'14'の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn
                                              , cv_uesama_kbn
                                              , cv_urikake_kbn ) )
    THEN
      --設定値がNULLの場合
      IF (cust_data_rec.tax_div IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.tax_div := cust_data_rec.addon_tax_div;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.tax_div := cust_data_rec.tax_div;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.tax_div := cust_data_rec.addon_tax_div;
    --
    END IF;
--
    -- ===============================
    -- 売上拠点
    -- ===============================
    --顧客区分が'13'、'14'、'16'、'17'の場合
    IF ( cust_data_rec.customer_class_code IN ( cv_trust_corp
                                              , cv_urikake_kbn
                                              , cv_tonya_kbn
                                              , cv_keikaku_kbn ) )
    THEN
      --設定値がNULLの場合
      IF (cust_data_rec.sale_base_code IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.sale_base_code := cust_data_rec.addon_sale_base_code;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.sale_base_code := cust_data_rec.sale_base_code;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.sale_base_code := cust_data_rec.addon_sale_base_code;
    --
    END IF;
--
    -- ===============================
    -- ピークカット開始時刻
    -- ===============================
    --顧客区分が'10'の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.longitude = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.longitude := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.longitude IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.longitude := cust_data_rec.addon_longitude;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.longitude := cust_data_rec.longitude;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.longitude := cust_data_rec.addon_longitude;
    --
    END IF;
--
    -- ===============================
    -- 稼働日カレンダ
    -- ===============================
    --顧客区分が'10'の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.calendar_code = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.calendar_code := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.calendar_code IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.calendar_code := cust_data_rec.addon_calendar_code;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.calendar_code := cust_data_rec.calendar_code;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.calendar_code := cust_data_rec.addon_calendar_code;
    --
    END IF;
--
    -- ===============================
    -- 消化計算用掛率
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.rate = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.rate := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.rate IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.rate := cust_data_rec.addon_rate;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.rate := TO_NUMBER(cust_data_rec.rate) / 100;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.rate := cust_data_rec.addon_rate;
    --
    END IF;
--
    -- ===============================
    -- 入金値引率
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.rcv_dsct_rate = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.receiv_discount_rate := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.rcv_dsct_rate IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.receiv_discount_rate := cust_data_rec.addon_rcv_dsct_rate;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.receiv_discount_rate := TO_NUMBER(cust_data_rec.rcv_dsct_rate);
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.receiv_discount_rate := cust_data_rec.addon_rcv_dsct_rate;
    --
    END IF;
--
    -- ===============================
    -- 消化計算締め日1
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.conclusion_day1 = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.conclusion_day1 := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.conclusion_day1 IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.conclusion_day1 := cust_data_rec.addon_conclusion_day1;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.conclusion_day1 := TO_NUMBER(cust_data_rec.conclusion_day1);
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.conclusion_day1 := cust_data_rec.addon_conclusion_day1;
    --
    END IF;
--
    -- ===============================
    -- 消化計算締め日2
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.conclusion_day2 = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.conclusion_day2 := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.conclusion_day2 IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.conclusion_day2 := cust_data_rec.addon_conclusion_day2;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.conclusion_day2 := TO_NUMBER(cust_data_rec.conclusion_day2);
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.conclusion_day2 := cust_data_rec.addon_conclusion_day2;
    --
    END IF;
--
    -- ===============================
    -- 消化計算締め日3
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.conclusion_day3 = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.conclusion_day3 := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.conclusion_day3 IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.conclusion_day3 := cust_data_rec.addon_conclusion_day3;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.conclusion_day3 := TO_NUMBER(cust_data_rec.conclusion_day3);
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.conclusion_day3 := cust_data_rec.addon_conclusion_day3;
    --
    END IF;
--
    -- ===============================
    -- 店舗営業用顧客コード
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF (cust_data_rec.store_cust_code = cv_null_bar)
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.store_cust_code := NULL;
      --設定値がNULLの場合
      ELSIF (cust_data_rec.store_cust_code IS NULL)
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.store_cust_code := cust_data_rec.addon_store_cust_code;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.store_cust_code := cust_data_rec.store_cust_code;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.store_cust_code := cust_data_rec.addon_store_cust_code;
    --
    END IF;
-- Ver1.10 add end
-- Ver1.14 add start
    -- ===============================
    -- ストレポ＆商談くん連携対象フラグ
    -- ===============================
    --eSM対象顧客区分の判定
    << check_esm_cust_class_loop >>
    FOR check_esm_cust_class_rec IN check_esm_cust_class_cur( cust_data_rec.customer_class_code )
    LOOP
      lv_esm_cust_class := check_esm_cust_class_rec.esm_cust_class;
    END LOOP check_esm_cust_class_loop;
--
    --eSM対象顧客区分の場合
    IF ( lv_esm_cust_class IS NOT NULL )
    THEN
      --設定値が'-'の場合
      IF ( cust_data_rec.esm_target_div = cv_null_bar )
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.esm_target_div := NULL;
      --設定値がNULLの場合
      ELSIF ( cust_data_rec.esm_target_div IS NULL )
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.esm_target_div := cust_data_rec.addon_esm_target_div;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.esm_target_div := cust_data_rec.esm_target_div;
      END IF;
    --eSM対象顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.esm_target_div := cust_data_rec.addon_esm_target_div;
    --
    END IF;
-- Ver1.14 add end
-- Ver1.16 add start
    -- ===============================
    -- 相殺用顧客コード
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF ( cust_data_rec.offset_cust_code = cv_null_bar )
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.offset_cust_code := NULL;
      --設定値がNULLの場合
      ELSIF ( cust_data_rec.offset_cust_code IS NULL )
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.offset_cust_code := cust_data_rec.addon_offset_cust_code;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.offset_cust_code := cust_data_rec.offset_cust_code;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.offset_cust_code := cust_data_rec.addon_offset_cust_code;
    --
    END IF;
--
    -- ===============================
    -- 取引先顧客コード
    -- ===============================
    --顧客区分「10：顧客」の場合
    IF ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
    THEN
      --設定値が'-'の場合
      IF ( cust_data_rec.bp_customer_code = cv_null_bar )
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.bp_customer_code := NULL;
      --設定値がNULLの場合
      ELSIF ( cust_data_rec.bp_customer_code IS NULL )
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.bp_customer_code := cust_data_rec.addon_bp_customer_code;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.bp_customer_code := cust_data_rec.bp_customer_code;
      END IF;
    --更新可能な顧客区分以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.bp_customer_code := cust_data_rec.addon_bp_customer_code;
    --
    END IF;
-- Ver1.16 add end
-- Ver1.19 add start
    -- ===============================
    -- カテゴリー商品計上区分
    -- ===============================
    --顧客区分「10：顧客」且つ、職責「業務管理部(顧客)」の場合
    IF    ( cust_data_rec.customer_class_code = cv_kokyaku_kbn )
      AND ( gv_management_resp = cv_gyomu_kokyaku_resp)
    THEN
      --設定値が'-'の場合
      IF ( cust_data_rec.latitude = cv_null_bar )
      THEN
        --NULLをセット
        l_xxcmm_cust_accounts.latitude := NULL;
      --設定値がNULLの場合
      ELSIF ( cust_data_rec.latitude IS NULL )
      THEN
        --更新前の値をセット
        l_xxcmm_cust_accounts.latitude := cust_data_rec.addon_latitude;
      ELSE
        --CSVの項目値をセット
        l_xxcmm_cust_accounts.latitude := cust_data_rec.latitude;
      END IF;
    --更新可能な顧客区分、職責以外の場合
    ELSE
      --更新前の値をセット
      l_xxcmm_cust_accounts.latitude := cust_data_rec.addon_latitude;
    --
    END IF;
-- Ver1.19 add end
-- Ver1.28 add start
    -- ===============================
    -- POS企業コード
    -- ===============================
    -- POS企業コードが'-'の場合
    IF (cust_data_rec.pos_enterprise_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.pos_enterprise_code := NULL;
    --  POS企業コードがNULL、または顧客区分が、10(顧客)、15(店舗営業)以外の場合
    ELSIF (cust_data_rec.pos_enterprise_code IS NULL) OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_tenpo_kbn)) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.pos_enterprise_code := cust_data_rec.addon_pos_enterprise_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.pos_enterprise_code := cust_data_rec.pos_enterprise_code;
    END IF;
    --
    -- ===============================
    -- POS店舗コード
    -- ===============================
    -- POS店舗コードが'-'の場合
    IF (cust_data_rec.pos_store_code = cv_null_bar) THEN
      -- NULLをセット
      l_xxcmm_cust_accounts.pos_store_code := NULL;
    --  POS店舗コードがNULL、または顧客区分が、10(顧客)、15(店舗営業)以外の場合
    ELSIF (cust_data_rec.pos_store_code IS NULL) OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_tenpo_kbn)) THEN
      -- 更新前の値をセット
      l_xxcmm_cust_accounts.pos_store_code := cust_data_rec.addon_pos_store_code;
    ELSE
      -- CSVの項目値をセット
      l_xxcmm_cust_accounts.pos_store_code := cust_data_rec.pos_store_code;
    END IF;
    --
-- Ver1.28 add end
    --
    -- ===============================
    -- 顧客追加情報マスタ更新
    -- ===============================
    UPDATE xxcmm_cust_accounts xca
    SET    xca.stop_approval_reason   = l_xxcmm_cust_accounts.stop_approval_reason       --中止理由
          ,xca.stop_approval_date     = l_xxcmm_cust_accounts.stop_approval_date         --中止決済日
          ,xca.sales_chain_code       = l_xxcmm_cust_accounts.sales_chain_code           --チェーン店コード（販売先）
          ,xca.delivery_chain_code    = l_xxcmm_cust_accounts.delivery_chain_code        --チェーン店コード（納品先）
          ,xca.policy_chain_code      = l_xxcmm_cust_accounts.policy_chain_code          --チェーン店コード（営業政策用）
          ,xca.chain_store_code       = l_xxcmm_cust_accounts.chain_store_code           --チェーン店コード（ＥＤＩ）
          ,xca.store_code             = l_xxcmm_cust_accounts.store_code                 --店舗コード
          ,xca.business_low_type      = l_xxcmm_cust_accounts.business_low_type          --業態（小分類）
          ,xca.invoice_printing_unit  = l_xxcmm_cust_accounts.invoice_printing_unit      --請求書印刷単位
          ,xca.invoice_code           = l_xxcmm_cust_accounts.invoice_code               --請求書用コード
-- Ver1.27 add start
          ,xca.invoice_tax_div        = l_xxcmm_cust_accounts.invoice_tax_div            --請求書消費税積上げ計算方式
-- Ver1.27 add end
          ,xca.industry_div           = l_xxcmm_cust_accounts.industry_div               --業種
          ,xca.bill_base_code         = l_xxcmm_cust_accounts.bill_base_code             --請求拠点
          ,xca.receiv_base_code       = l_xxcmm_cust_accounts.receiv_base_code           --入金拠点
          ,xca.delivery_base_code     = l_xxcmm_cust_accounts.delivery_base_code         --納品拠点
          ,xca.selling_transfer_div   = l_xxcmm_cust_accounts.selling_transfer_div       --売上実績振替
          ,xca.card_company           = l_xxcmm_cust_accounts.card_company               --カード会社
          ,xca.wholesale_ctrl_code    = l_xxcmm_cust_accounts.wholesale_ctrl_code        --問屋管理コード
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
          ,xca.past_customer_status   = l_xxcmm_cust_accounts.past_customer_status       --前月顧客ステータス
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
          ,xca.ship_storage_code      = l_xxcmm_cust_accounts.ship_storage_code          --出荷元保管場所
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_本稼動_07553 add start by K.Kubo
          ,xca.delivery_order         = l_xxcmm_cust_accounts.delivery_order             --配送順（EDI）
          ,xca.edi_district_code      = l_xxcmm_cust_accounts.edi_district_code          --EDI地区コード（EDI）
          ,xca.edi_district_name      = l_xxcmm_cust_accounts.edi_district_name          --EDI地区名（EDI）
          ,xca.edi_district_kana      = l_xxcmm_cust_accounts.edi_district_kana          --EDI地区名カナ（EDI）
          ,xca.tsukagatazaiko_div     = l_xxcmm_cust_accounts.tsukagatazaiko_div         --通過在庫型区分（EDI）
          ,xca.deli_center_code       = l_xxcmm_cust_accounts.deli_center_code           --EDI納品センターコード
          ,xca.deli_center_name       = l_xxcmm_cust_accounts.deli_center_name           --EDI納品センター名
          ,xca.edi_forward_number     = l_xxcmm_cust_accounts.edi_forward_number         --EDI伝送追番
          ,xca.cust_store_name        = l_xxcmm_cust_accounts.cust_store_name            --顧客店舗名称
          ,xca.torihikisaki_code      = l_xxcmm_cust_accounts.torihikisaki_code          --取引先コード
-- 2011/12/05 Ver1.7 E_本稼動_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_本稼動_09272 add start by S.Niki
          ,xca.vist_target_div        = l_xxcmm_cust_accounts.vist_target_div            --訪問対象区分
-- 2012/03/13 Ver1.8 E_本稼動_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
          ,xca.intro_chain_code1      = l_xxcmm_cust_accounts.intro_chain_code1          --紹介者チェーンコード１
          ,xca.intro_chain_code2      = l_xxcmm_cust_accounts.intro_chain_code2          --控除用チェーンコード
          ,xca.sales_head_base_code   = l_xxcmm_cust_accounts.sales_head_base_code       --販売先本部担当拠点
          ,xca.cnvs_base_code         = l_xxcmm_cust_accounts.cnvs_base_code             --獲得拠点コード
          ,xca.cnvs_business_person   = l_xxcmm_cust_accounts.cnvs_business_person       --獲得営業員
          ,xca.new_point_div          = l_xxcmm_cust_accounts.new_point_div              --新規ポイント区分
          ,xca.new_point              = l_xxcmm_cust_accounts.new_point                  --新規ポイント
          ,xca.intro_base_code        = l_xxcmm_cust_accounts.intro_base_code            --紹介拠点コード
          ,xca.intro_business_person  = l_xxcmm_cust_accounts.intro_business_person      --紹介営業員
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
-- Ver1.10 add start
          ,xca.tax_div                = l_xxcmm_cust_accounts.tax_div                    --消費税区分
          ,xca.sale_base_code         = l_xxcmm_cust_accounts.sale_base_code             --売上拠点
          ,xca.longitude              = l_xxcmm_cust_accounts.longitude                  --ピークカット開始時刻
          ,xca.calendar_code          = l_xxcmm_cust_accounts.calendar_code              --稼働日カレンダ
          ,xca.rate                   = l_xxcmm_cust_accounts.rate                       --消化計算用掛率
          ,xca.receiv_discount_rate   = l_xxcmm_cust_accounts.receiv_discount_rate       --入金値引率
          ,xca.conclusion_day1        = l_xxcmm_cust_accounts.conclusion_day1            --消化計算締め日1
          ,xca.conclusion_day2        = l_xxcmm_cust_accounts.conclusion_day2            --消化計算締め日2
          ,xca.conclusion_day3        = l_xxcmm_cust_accounts.conclusion_day3            --消化計算締め日3
          ,xca.store_cust_code        = l_xxcmm_cust_accounts.store_cust_code            --店舗営業用顧客コード
-- Ver1.10 add end
-- Ver1.14 add start
          ,xca.esm_target_div         = l_xxcmm_cust_accounts.esm_target_div             --ストレポ＆商談くん連携対象フラグ
-- Ver1.14 add end
-- Ver1.16 add start
          ,xca.offset_cust_code       = l_xxcmm_cust_accounts.offset_cust_code           --相殺用顧客コード
          ,xca.bp_customer_code       = l_xxcmm_cust_accounts.bp_customer_code           --取引先顧客コード
-- Ver1.16 add end
-- Ver1.19 add start
          ,xca.latitude               = l_xxcmm_cust_accounts.latitude                   --カテゴリー商品計上区分
-- Ver1.19 add end
-- Ver1.28 add start
          ,xca.pos_enterprise_code    = l_xxcmm_cust_accounts.pos_enterprise_code        --POS企業コード
          ,xca.pos_store_code         = l_xxcmm_cust_accounts.pos_store_code             --POS店舗コード
-- Ver1.28 add end
          ,xca.last_updated_by        = cn_last_updated_by                               --最終更新者
          ,xca.last_update_date       = cd_last_update_date                              --最終更新日
          ,xca.request_id             = cn_request_id                                    --要求ID
          ,xca.program_application_id = cn_program_application_id                        --コンカレント・プログラム･アプリケーションID
          ,xca.program_id             = cn_program_id                                    --コンカレント・プログラムID
          ,xca.program_update_date    = cd_program_update_date                           --プログラム更新日
    WHERE  xca.customer_id = cust_data_rec.customer_id
    ;
    -- 変数初期化
    l_xxcmm_cust_accounts := NULL;
-- 2009/10/23 modify end by Yutaka.Kuboshima
    --
    -- ===============================
    -- 顧客法人情報更新
    -- ===============================
    --顧客区分が'13'（法人顧客（与信管理先））のときのみ、顧客法人情報更新
    IF (cust_data_rec.customer_class_code = cv_trust_corp) THEN
      UPDATE xxcmm_mst_corporate xmc
      SET    xmc.credit_limit           = DECODE(cust_data_rec.credit_limit,        --与信限度額
                                                 NULL,
                                                 cust_data_rec.addon_credit_limit,
                                                 cust_data_rec.credit_limit),
             xmc.decide_div             = DECODE(cust_data_rec.decide_div,          --判定区分
                                                 NULL,
                                                 cust_data_rec.addon_decide_div,
                                                 cust_data_rec.decide_div),
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add start by T.Nakano
             xmc.tdb_code               = l_xxcmm_mst_corporate.tdb_code,           --TDBコード
             xmc.approval_date          = l_xxcmm_mst_corporate.approval_date,      --決裁日付
             xmc.base_code              = l_xxcmm_mst_corporate.base_code,          --本部担当拠点
-- 2013/04/17 Ver1.9 E_本稼動_09963追加対応 add end by T.Nakano
             xmc.last_updated_by        = fnd_global.user_id,                       --最終更新者
             xmc.last_update_date       = sysdate,                                  --最終更新日
             xmc.request_id             = fnd_profile.value(cv_conc_request_id),    --要求ID
             xmc.program_application_id = fnd_profile.value(cv_prog_appl_id),       --コンカレント・プログラム･アプリケーションID
             xmc.program_id             = fnd_profile.value(cv_conc_program_id),    --コンカレント・プログラムID
             xmc.program_update_date    = sysdate                                   --プログラム更新日
      WHERE  xmc.customer_id  = cust_data_rec.customer_id
      ;
    END IF;
--
  END LOOP cust_data_loop;
--
  EXCEPTION
    WHEN cust_rock_err_expt THEN                       --*** ロック取得失敗例外 ***
      --ロックエラー時メッセージ取得
      gv_out_msg    := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_rock_err_msg
                        );
      lv_errmsg     := gv_out_msg;
      lv_errbuf     := gv_out_msg;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --ロック取得失敗例外時、対象件数、エラー件数は全件とする
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_cust_err_expt THEN                       --*** 顧客マスタ更新エラー ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --顧客マスタ更新エラー時、対象件数、エラー件数は全件とする
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_party_err_expt THEN                      --*** パーティマスタ更新エラー ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --パーティマスタ更新エラー時、対象件数、エラー件数は全件とする
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_csu_err_expt THEN                        --*** 顧客使用目的マスタ更新エラー ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --顧客使用目的マスタ更新エラー時、対象件数、エラー件数は全件とする
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_location_err_expt THEN                   --*** 顧客事業所マスタ更新エラー ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --顧客事業所マスタ更新エラー時、対象件数、エラー件数は全件とする
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
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
  END rock_and_update_cust;
--
  /**********************************************************************************
   * Procedure Name   : close_process
   * Description      : 終了処理(A-5)
   ***********************************************************************************/
  PROCEDURE close_process(
    in_file_id      IN  NUMBER,              --   ファイルID
    ov_errbuf       OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_process'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    DELETE xxcmm_wk_cust_batch_regist;
    DELETE xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id;
    COMMIT;
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
  END close_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id                IN  NUMBER,       --ファイルID
    iv_format_pattern         IN  VARCHAR2,     --ファイルフォーマット
    ov_errbuf                 OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_real_errbuf   VARCHAR2(5000);  --A-3・A-4時のエラー・メッセージ
    lv_real_retcode  VARCHAR2(1);     --A-3・A-4時のリターン・コード
    lv_real_errmsg   VARCHAR2(5000);  --A-3・A-4時のユーザー・エラー・メッセージ
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
--
    --パラメータ出力
    --ファイルID
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_file_id
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => TO_CHAR(in_file_id)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --ファイルタイプ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_file_content_type
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_format_pattern
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- 業務日付取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_本稼動_00778 add start by Yutaka.Kuboshima
    -- 会計カレンダコード取得
    gv_gl_cal_code := fnd_profile.value(cv_profile_gl_cal);
    IF (gv_gl_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- アプリケーション短縮名
                      iv_name           =>  cv_profile_err_msg,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_gl_cal_name        -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 営業システム会計帳簿定義名取得
    gv_ar_set_of_books := fnd_profile.value(cv_profile_ar_bks);
    IF (gv_ar_set_of_books IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- アプリケーション短縮名
                      iv_name           =>  cv_profile_err_msg,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_set_of_books_name  -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
-- 2010/01/04 Ver1.3 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_本稼動_02295 add start by Yutaka.Kuboshima
    --
    -- 在庫組織コード取得
    gv_organization_code := fnd_profile.value(cv_organization_code);
    IF (gv_organization_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- アプリケーション短縮名
                      iv_name           =>  cv_profile_err_msg,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_org_code   -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 顧客一括更新データ項目数取得
    gn_item_num := TO_NUMBER(fnd_profile.value(cv_csv_item_num));
    IF (gn_item_num IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- アプリケーション短縮名
                      iv_name           =>  cv_profile_err_msg,   -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_csv_item_num_name  -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 職責管理プロファイル取得
    gv_management_resp := fnd_profile.value(cv_management_resp);
    IF (gv_management_resp IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,       -- アプリケーション短縮名
                      iv_name           =>  cv_profile_err_msg,     -- プロファイル取得エラー
                      iv_token_name1    =>  cv_tkn_ng_profile,      -- トークン(NG_PROFILE)
                      iv_token_value1   =>  cv_management_resp_name -- プロファイル定義名
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 職責管理プロファイルで取得した値が'XXCMM_RESP_011'であるか
    IF (gv_management_resp = cv_joho_kanri_resp) THEN
      -- 職責管理フラグを'Y'に設定
      gv_resp_flag := cv_yes;
    ELSE
      -- 職責管理フラグを'N'に設定
      gv_resp_flag := cv_no;
    END IF;
-- 2010/04/23 Ver1.6 E_本稼動_02295 add end by Yutaka.Kuboshima
-- Ver1.26 add start
--
   --========================================
   -- ユーザーID取得処理
   --========================================
   gn_user_id := fnd_global.user_id;
   IF ( gn_user_id IS NULL ) THEN
     lv_errmsg               :=  xxccp_common_pkg.get_msg(
       iv_application        =>  gv_xxcok_msg_kbn,
       iv_name               =>  cv_msg_user_id_err
     );
     lv_errbuf := lv_errmsg;
     RAISE global_api_expt;
   END IF;
--
   --========================================
   -- 所属拠点コード取得処理
   --========================================
   gv_user_base_code := xxcok_common_pkg.get_base_code_f(
     id_proc_date            =>  gd_process_date,
     in_user_id              =>  gn_user_id
     );
   IF ( gv_user_base_code IS NULL ) THEN
     lv_errmsg               :=  xxccp_common_pkg.get_msg(
       iv_application        =>  gv_xxcok_msg_kbn,
       iv_name               =>  cv_msg_user_base_code_err,
       iv_token_name1        =>  cv_token_user_id,
       iv_token_value1       =>  gn_user_id
     );
     lv_errbuf := lv_errmsg;
     RAISE global_api_expt;
   END IF;
-- Ver1.26 add end
    --
    -- ===============================
    -- ファイルアップロードI/Fテーブル取得処理(A-1)・顧客一括更新用ワークテーブル登録処理(A-2)
    -- ===============================
    cust_data_make_wk(
       in_file_id            -- ファイルID
      ,iv_format_pattern     -- ファイルフォーマット
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    --ファイルアップロードI/Fテーブル取得処理エラー時、
    --又は顧客一括更新用ワークテーブル登録処理エラー時は処理をスキップ
    IF (lv_retcode = cv_status_error) THEN
      NULL;
    ELSE
      -- ===============================
      -- テーブルロック処理(A-3)・顧客一括更新処理(A-4)
      -- ===============================
      rock_and_update_cust(
         in_file_id              -- ファイルID
        ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
        ,lv_retcode              -- リターン・コード             --# 固定 #
        ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      --テーブルロック処理(A-3)・顧客一括更新処理(A-4)エラー時、ロールバック
      IF (lv_retcode = cv_status_error) THEN
        --ROLLBACK
        ROLLBACK;
      END IF;
    END IF;
--
    lv_real_errbuf  := lv_errbuf;
    lv_real_retcode := lv_retcode;
    lv_real_errmsg  := lv_errmsg;
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    --ステータスに関わらず、アップロードテーブルとワークテーブルは削除する
    close_process(
       in_file_id              -- ファイルID
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    --ファイルアップロードI/Fテーブル取得処理エラー時、
    --又は顧客一括更新用ワークテーブル登録処理エラー時、もしくは
    --テーブルロック処理エラー時、
    --顧客一括更新処理エラー時、RAISE
    IF (lv_real_retcode = cv_status_error) THEN
      --エラー処理
      lv_errmsg := lv_real_errmsg;
      lv_errbuf := lv_real_errbuf;
      RAISE global_process_expt;
    END IF;
--
    --終了処理処理エラー時
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
-- Ver1.26 add start
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- Ver1.26 add end
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
    errbuf                    OUT    VARCHAR2,  --エラーメッセージ #固定#
    retcode                   OUT    VARCHAR2,  --エラーコード     #固定#
    iv_file_id                IN     VARCHAR2,  --ファイルID
    iv_format_pattern         IN     VARCHAR2   --ファイルフォーマット
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
       TO_NUMBER(iv_file_id)     --ファイルID
      ,iv_format_pattern         --ファイルフォーマット
      ,lv_errbuf                 --エラー・メッセージ           --# 固定 #
      ,lv_retcode                --リターン・コード             --# 固定 #
      ,lv_errmsg                 --ユーザー・エラー・メッセージ --# 固定 #
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
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
END XXCMM003A29C;
/
