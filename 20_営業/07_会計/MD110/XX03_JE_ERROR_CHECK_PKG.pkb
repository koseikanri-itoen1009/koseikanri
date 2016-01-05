CREATE OR REPLACE PACKAGE BODY xx03_je_error_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : xx03_je_error_check_pkg(body)
 * Description      : 仕訳エラーチェック共通関数
 * MD.070           : 仕訳エラーチェック共通関数 OCSJ/BFAFIN/MD070/F313
 * Version          : 11.5.10.2.8
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  je_error_check            仕訳エラーチェック：呼出元プログラムから制御を受取り、
 *                            各エラーチェックサブ関数を呼び出しエラーチェックを行な
 *                            います。
 *
 *  ccid_check                CCIDチェック      ：AFFとDFFの各チェック、AFFとDFFの組
 *                            合せチェックを行ないます。
 *
 *  period_check              GL会計期間チェック：GL記帳日がオープンされているかチェ
 *                            ックを行ないます。
 *
 *  aff_dff_check             AFF_DFFチェックAFFとDFFの各チェック、AFFとDFFの組合せチ
 *                            ェックを行ないます。
 *
 *  balance_check             仕訳バランスチェック：仕訳内の貸借金額の合計が一致する
 *                            かチェックを行ないます。
 *
 *  tax_range_check           消費税額許容範囲チェック：仕訳内の消費税が許容範囲内に
 *                            あるかチェックを行ないます。
 *
 *  cf_balance_check          CFバランスチェック：キャッシュフローが仕訳内でバランス
 *                            しているかチェックを行ないます。
 *
 *  error_importance_check    エラー重大度チェック：発生したエラーのうち最も重大度の
 *                            高いエラーを選択します。
 *
 *  get_check_id              シーケンスより最新のチェックIDを取得します。
 *
 *  ins_error_tbl             エラー情報テーブル出力関数。
 *
 * Change Record
 * ------------ -------------- ------------ -------------------------------------------------
 *  Date         Ver.           Editor       Description
 * ------------ -------------- ------------ -------------------------------------------------
 *  2004/01/06   1.0            M.Yamamura   新規作成
 *  2004/01/23   1.1            M.Yamamura   TE070実施時の不具合修正
 *  2004/01/26   1.2            M.Yamamura   TE080実施時の不具合修正
 *  2004/01/29   1.3            M.Yamamura   TE080実施時の不具合修正(cf_balance_check)
 *  2004/02/04   1.4            N.Fujikawa   tax_range_checkで許容範囲違反の際、
 *                                           ステータスを警告にするようにする
 *  2004/02/12   1.5            N.Fujikawa   1.aff_dff_checkにおいて、勘定科目DFFの相手先必須
 *                                             区分が’Y’の場合の条件を追加
 *                                           2.cf_balance_checkにおいて、対象データのSQL文から
 *                                             ｢er.incr_decr_reason_code is not null｣の条件を削除
 *  2004/02/20   1.6            N.Fujikawa   1.DFF税区分チェックにおいて、税区分がNullの場合の
 *                                             チェック条件を変更
 *                                           2.DFF税区分チェックにおいて、勘定科目の税区分必須区分
 *                                             の条件を変更
 *  2004/02/24   1.7            N.Fujikawa   1.aff_dff_checkにおいて、CF組み合わせマスタの存在
 *                                             チェックの際に、増減事由がNullの場合を考慮
 *                                           2.aff_dff_checkにおいて、起票部門がNullの場合は
 *                                             エラーにしないように変更
 *  2004/02/25   1.8            N.Fujikawa   1.tax_range_checkにおいて、消費税を含まなくても良い
 *                                             仕訳（税金行を以外の合計値で貸借バランスがとれて
 *                                             いる仕訳）は、消費税許容範囲率チェックでエラーに
 *                                             としないように変更
 *  2004/02/26   1.9            N.Fujikawa   1.tax_range_checkにおいて、通貨が取得できなかった際
 *                                             には精度を2にするように変更
 *  2004/02/27   1.10           K.Ikeda      1.tax_range_checkにおいて、税区分Nullもチェック対象
 *                                             とし、税率0%のときは税金行でない行の合計が0になる
 *                                             よう変更
 *                                           2.tax_range_checkにおいて、税金行でない行の合計が0
 *                                             のとき、税金行の合計が0でなければエラーにするよう
 *                                             変更
 *                                           3.tax_range_checkの許容範囲率チェックにおいて、差額
 *                                             の絶対値でなく差額の率の絶対値で判断するよう変更
 *  2004/12/09   1.11           H.Umetsu     aff_dff_checkにおいて、エラーメッセージ中のAFFセグ
 *                                           メント名称を共通から取得するように変更
 *  2004/12/27   1.12           T.Shigekawa  xx03_error_info表にdr_crカラムを追加。貸借区分を
 *                                           格納するように変更
 *  2005/10/20   11.5.10.1.5    Y.Matsumura  勘定科目マスタの税区分必須区分と税コードマスタの
 *                                           集計区分の組合せが、2-2,2-null,3-1,3-null,9-1,9-2,
 *                                           null-1,null-2でエラーとなるように修正
 *  2005/12/15   11.5.10.1.6    A.Okusa      税金コードの有効チェック対応
 *                                           税区分のマスタチェックに税区分の有効日を追加。
 *                                           消費税額許容範囲チェック用カーソル内に
 *                                           税金コードの有効チェック追加。
 *  2005/12/28   11.5.10.1.6B   S.Morisawa   AFFの各セグメントの値チェックにおいて
 *                                           ｢転記の許可｣が｢Y｣のもののみチェックOKとし、
 *                                           ｢Y｣以外（｢N｣）の場合はエラーとするロジックを追加
 *  2006/01/16   11.5.10.1.6C   S.Morisawa   1.CF組合せマスタ取得SQLの条件に会計帳簿IDを追加
 *                                           2.増減事由Nullの時もCF組合せマスタチェックを行うよう修正
 *  2005/10/20   11.5.10.1.6D   Y.Matsumura  通貨チェックをGL記帳日も条件に含めるよう修正
 *  2006/10/04   11.5.10.2.6    S.Morisawa   マスタチェックの見直し(有効日のチェックを請求書日付で
 *                                           行なう項目とSYSDATEで行なう項目を再確認)
 *  2015/03/24   11.5.10.2.7    Y.Shoji      消費税額許容範囲チェックカーソルの会社コードを
 *                                           固定値：001（本社）に変更する。
 *  2015/12/17   11.5.10.2.8    S.Niki       [E_本稼動_13421]aff_dff_checkに中止顧客チェック追加
 *
 *****************************************************************************************/
--
--
  -- ===============================
  -- *** グローバル定数 ***
  -- ===============================
--
  -- ===============================
  -- グローバル・カーソル
  -- ===============================
  CURSOR xx03_error_checks_cur(
    in_check_id       IN  xx03_error_checks.check_id%TYPE   -- 1.チェックID
  )
  IS
    SELECT
      xec.check_id              ,-- チェックID
      xec.journal_id            ,-- 仕訳ID
      xec.line_number           ,-- 行番号
      xec.gl_date               ,-- GL記帳日
      xec.period_name           ,-- GL会計期間
      xec.currency_code         ,-- 通貨
      xec.code_combination_id   ,-- CCID
      xec.segment1              ,-- 会社
      xec.segment2              ,-- 部門
      xec.segment3              ,-- 勘定科目
      xec.segment4              ,-- 補助科目
      xec.segment5              ,-- 相手先
      xec.segment6              ,-- 事業区分
      xec.segment7              ,-- プロジェクト
      xec.segment8              ,-- 予備
      xec.tax_code              ,-- 税区分
      xec.incr_decr_reason_code ,-- 増減事由
      xec.slip_number           ,-- 伝票番号
      xec.input_department      ,-- 起票部門
      xec.input_user            ,-- 伝票入力者
      xec.orig_slip_number      ,-- 修正元伝票番号
      xec.recon_reference       ,-- 消込参照
      xec.entered_dr            ,-- 借方金額
      xec.entered_cr            ,-- 貸方金額
-- 追加 ver1.12 開始
      decode(xec.entered_dr,null,
             decode(xec.entered_cr,null,' ','CR'),
             decode(xec.entered_cr,null,'DR',' ')) as dr_cr, --貸借区分
-- 追加 ver1.12 終了
      xec.attribute_category    ,-- DFFカテゴリ
      xec.attribute1            ,-- DFF予備1
      xec.attribute2            ,-- DFF予備2
      xec.attribute3            ,-- DFF予備3
      xec.attribute4            ,-- DFF予備4
      xec.attribute5            ,-- DFF予備5
      xec.attribute6            ,-- DFF予備6
      xec.attribute7            ,-- DFF予備7
      xec.attribute8            ,-- DFF予備8
      xec.attribute9            ,-- DFF予備9
      xec.attribute10           ,-- DFF予備10
      xec.attribute11           ,-- DFF予備11
      xec.attribute12           ,-- DFF予備12
      xec.attribute13           ,-- DFF予備13
      xec.attribute14           ,-- DFF予備14
      xec.attribute15           ,-- DFF予備15
      xec.attribute16           ,-- DFF予備16
      xec.attribute17           ,-- DFF予備17
      xec.attribute18           ,-- DFF予備18
      xec.attribute19           ,-- DFF予備19
      xec.attribute20           ,-- DFF予備20
      xec.created_by            ,-- 作成者
      xec.creation_date         ,-- 作成日
      xec.last_updated_by       ,-- 最終更新者
      xec.last_update_date      ,-- 最終更新日
      xec.last_update_login     ,-- 最終ログインID
      xec.request_id            ,-- 要求ID
      xec.program_application_id,-- プログラムアプリケーションID
      xec.program_update_date   ,-- プログラム更新日
      xec.program_id             -- プログラムID
  FROM xx03_error_checks xec
  WHERE xec.check_id = in_check_id
  ;

  --エラー出力関数
  FUNCTION ins_error_tbl(
    in_check_id     IN  NUMBER          , --1.チェックID
    iv_journal_id   IN  VARCHAR2        , --2.仕訳キー
    in_line_number  IN  NUMBER          , --3.行番号
-- 追加 ver1.12 開始
    iv_dr_cr        IN  VARCHAR2        , --4.貸借区分
-- 追加 ver1.12 終了
    iv_error_code   IN  VARCHAR2        , --5.エラーコード
    it_tokeninfo    IN  TOKENINFO_TTYPE , --6.トークン情報
    iv_status       IN  VARCHAR2        , --7.ステータス
    iv_application  IN  VARCHAR2 DEFAULT 'XX03' )
    RETURN VARCHAR2;

--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
--
--###########################  固定部 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : je_error_check
   * Description      : 仕訳エラーチェック
   ***********************************************************************************/
  FUNCTION je_error_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.je_error_check'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

    --既存チェックＩＤ存在確認用カーソル
    CURSOR xx03_error_info_cur(
          in_check_id         IN  xx03_error_info.check_id%TYPE           -- 1.チェックID
    ) IS
    SELECT
      count('X') recs
    FROM
      xx03_error_info
    WHERE
      check_id =in_check_id
    ;
    xx03_error_info_rec           xx03_error_info_cur%ROWTYPE;              --テーブルレコード

    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    chk_para_expt           EXCEPTION;  --パラメータチェック例外
    chk_outdata_expt        EXCEPTION;  --既存データ存在例外

--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************

    --RETURN cv_status_success;

    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RAISE chk_para_expt;
    END IF;

    --2.  既存チェックＩＤ存在チェック
    --出力先のxx03_error_info　 (エラー情報テーブル)にパラメータのチェックＩＤの既存レコード
    --が存在するかをチェックします。

    -- 2.エラー情報テーブル読込み
    OPEN xx03_error_info_cur(
        in_check_id
    );
    FETCH xx03_error_info_cur INTO xx03_error_info_rec;

    IF xx03_error_info_cur%NOTFOUND THEN
      --COUNT関数なのであり得ないケース
      --カーソルのクローズ
      CLOSE xx03_error_info_cur;
      RETURN cv_status_error;
    ELSE
      IF xx03_error_info_rec.recs != 0  THEN
        --count(‘X’) > 0 であれば既存データ存在例外(chk_outdata_expt)を呼びだします。

        CLOSE xx03_error_info_cur;
        RAISE chk_outdata_expt;
      END IF;
    END IF;
    CLOSE xx03_error_info_cur;

    --3.  CCIDチェック起動
    lv_ret := xx03_je_error_check_pkg.ccid_check(
        in_check_id      --1.チェックID
    );

    --関数戻りコードにパラメータエラー(‘P’)が返ってきた場合は、パラメータに以下の値を設
    --定し、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを
    --出力します。

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.チェックID
          ' '                               , --2.仕訳キー
          0                                 , --3.行番号
-- 追加 ver1.12 開始
          ' '                               , --4.貸借区分
-- 追加 ver1.12 終了
          lv_error_code   ,                   --5.エラーコード
          lt_tokeninfo    ,                   --6.トークン情報
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --4.  GL会計期間チェック起動
    lv_ret := xx03_je_error_check_pkg.period_check(
        in_check_id      --1.チェックID
    );

    --関数戻りコードにパラメータエラー(‘P’)が返ってきた場合は、パラメータに以下の値を設
    --定し、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを
    --出力します。

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.チェックID
          ' '                               , --2.仕訳キー
          0                                 , --3.行番号
-- 追加 ver1.12 開始
          ' '                               , --4.貸借区分
-- 追加 ver1.12 終了
          lv_error_code   ,                   --5.エラーコード
          lt_tokeninfo    ,                   --6.トークン情報
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --5.  AFF・DFFチェック起動
    lv_ret := xx03_je_error_check_pkg.aff_dff_check(
        in_check_id      --1.チェックID
    );

    --関数戻りコードにパラメータエラー(‘P’)が返ってきた場合は、パラメータに以下の値を設
    --定し、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを
    --出力します。

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.チェックID
          ' '                               , --2.仕訳キー
          0                                 , --3.行番号
-- 追加 ver1.12 開始
          ' '                               , --4.貸借区分
-- 追加 ver1.12 終了
          lv_error_code   ,                   --5.エラーコード
          lt_tokeninfo    ,                   --6.トークン情報
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --6.  仕訳バランスチェック起動
    lv_ret := xx03_je_error_check_pkg.balance_check(
        in_check_id      --1.チェックID
    );

    --関数戻りコードにパラメータエラー(‘P’)が返ってきた場合は、パラメータに以下の値を設
    --定し、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを
    --出力します。

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.チェックID
          ' '                               , --2.仕訳キー
          0                                 , --3.行番号
-- 追加 ver1.12 開始
          ' '                               , --4.貸借区分
-- 追加 ver1.12 終了
          lv_error_code   ,                   --5.エラーコード
          lt_tokeninfo    ,                   --6.トークン情報
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --7.  消費税許容範囲チェック起動
    lv_ret := xx03_je_error_check_pkg.tax_range_check(
        in_check_id      --1.チェックID
    );

    --関数戻りコードにパラメータエラー(‘P’)が返ってきた場合は、パラメータに以下の値を設
    --定し、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを
    --出力します。

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.チェックID
          ' '                               , --2.仕訳キー
          0                                 , --3.行番号
-- 追加 ver1.12 開始
          ' '                               , --4.貸借区分
-- 追加 ver1.12 終了
          lv_error_code   ,                   --5.エラーコード
          lt_tokeninfo    ,                   --6.トークン情報
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --8.  CFバランスチェック起動
    lv_ret := xx03_je_error_check_pkg.cf_balance_check(
        in_check_id      --1.チェックID
    );

    --関数戻りコードにパラメータエラー(‘P’)が返ってきた場合は、パラメータに以下の値を設
    --定し、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを
    --出力します。

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.チェックID
          ' '                               , --2.仕訳キー
          0                                 , --3.行番号
-- 追加 ver1.12 開始
          ' '                               , --4.貸借区分
-- 追加 ver1.12 終了
          lv_error_code   ,                   --5.エラーコード
          lt_tokeninfo    ,                   --6.トークン情報
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --9.  エラー重大度チェック起動
    lv_ret := xx03_je_error_check_pkg.error_importance_check(
        in_check_id      --1.チェックID
    );

    --戻り値にエラー重大度チェックで取得した戻り値を設定し、処理を終了します
    lv_ret_status := lv_ret ;

--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN chk_para_expt THEN       --パラメータチェック例外
      RETURN cv_status_param_err; --'P'
    WHEN chk_outdata_expt THEN    --既存データ存在例外
      RETURN cv_status_error;     --'E'
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END je_error_check;
--
  /**********************************************************************************
   * Procedure Name   : ccid_check
   * Description      : CCIDチェック
   ***********************************************************************************/
  FUNCTION ccid_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.ccid_check'; -- プログラム名

    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ln_set_of_books_id              gl_sets_of_books.set_of_books_id%TYPE;      --帳簿ID
    ln_chart_of_accounts_id         gl_sets_of_books.chart_of_accounts_id%TYPE; --勘定体系ID
    xx03_error_checks_rec           xx03_error_checks_cur%ROWTYPE;              --エラーチェックテーブルレコード

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

    lv_segment1                     gl_code_combinations.segment1                     %TYPE;--セグメント1　（会社）
    lv_segment2                     gl_code_combinations.segment2                     %TYPE;--セグメント2　（部門）
    lv_segment3                     gl_code_combinations.segment3                     %TYPE;--セグメント3　（勘定科目）
    lv_segment4                     gl_code_combinations.segment4                     %TYPE;--セグメント4　（補助科目）
    lv_segment5                     gl_code_combinations.segment5                     %TYPE;--セグメント5　（相手先）
    lv_segment6                     gl_code_combinations.segment6                     %TYPE;--セグメント6　（事業区分）
    lv_segment7                     gl_code_combinations.segment7                     %TYPE;--セグメント7　（プロジェクト）
    lv_segment8                     gl_code_combinations.segment8                     %TYPE;--セグメント8　（予備）
    lv_enabled_flag                 gl_code_combinations.enabled_flag                 %TYPE;--使用可能
    lv_detail_posting_allowed_flag  gl_code_combinations.detail_posting_allowed_flag  %TYPE;--転記の許可
    lv_start_date_active            gl_code_combinations.start_date_active            %TYPE;--有効開始日
    lv_end_date_active              gl_code_combinations.end_date_active              %TYPE;--有効終了日
    ln_code_combination_id          gl_code_combinations.code_combination_id          %TYPE;--CCID

    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    local_continue       EXCEPTION;

  --
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
  -- ***********************************************
  -- ***      共通関数処理ロジックの記述         ***
  -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    -- 2. 帳簿ID取得
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID');

    -- 3. 勘定体系ID取得
    SELECT gsob.chart_of_accounts_id
    INTO   ln_chart_of_accounts_id
    FROM   gl_sets_of_books gsob
    WHERE  gsob.set_of_books_id = ln_set_of_books_id
    ;
    --4.エラーチェックテーブル読み込み
     OPEN xx03_error_checks_cur(
        in_check_id         -- 1.チェックID
    );

    <<ccid_check_loop>>
    LOOP
      FETCH xx03_error_checks_cur INTO xx03_error_checks_rec;
      EXIT WHEN xx03_error_checks_cur%NOTFOUND;

      BEGIN

        --1)GL記帳日チェック
        --  GL記帳日がNULLの場合、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エ
        --  ラー情報テーブルを出力します。

        IF xx03_error_checks_rec.gl_date IS NULL THEN
          lv_error_code   := 'APP-XX03-03042';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error       );
          lt_tokeninfo.DELETE;

          --戻り値更新
          lv_ret_status := cv_status_error;
          --次レコードを処理します。
          RAISE local_continue;
        END IF;

        --2)セグメント値(SEGMENT１～8)に値が設定されているレコードか判定します。

        IF  xx03_error_checks_rec. segment1 IS NULL AND
            xx03_error_checks_rec. segment2 IS NULL AND
            xx03_error_checks_rec. segment3 IS NULL AND
            xx03_error_checks_rec. segment4 IS NULL AND
            xx03_error_checks_rec. segment5 IS NULL AND
            xx03_error_checks_rec. segment6 IS NULL AND
            xx03_error_checks_rec. segment7 IS NULL AND
            xx03_error_checks_rec. segment8 IS NULL THEN
            --「CCID展開」を実行します。
          BEGIN
            SELECT
              segment1,                       --セグメント1　（会社）
              segment2,                       --セグメント2　（部門）
              segment3,                       --セグメント3　（勘定科目）
              segment4,                       --セグメント4　（補助科目）
              segment5,                       --セグメント5　（相手先）
              segment6,                       --セグメント6　（事業区分）
              segment7,                       --セグメント7　（プロジェクト）
              segment8,                       --セグメント8　（予備）
              enabled_flag,                   --使用可能
              detail_posting_allowed_flag,    --転記の許可
              start_date_active,              --有効開始日
              end_date_active                 --有効終了日
            INTO
              lv_segment1,                    --セグメント1　（会社）
              lv_segment2,                    --セグメント2　（部門）
              lv_segment3,                    --セグメント3　（勘定科目）
              lv_segment4,                    --セグメント4　（補助科目）
              lv_segment5,                    --セグメント5　（相手先）
              lv_segment6,                    --セグメント6　（事業区分）
              lv_segment7,                    --セグメント7　（プロジェクト）
              lv_segment8,                    --セグメント8　（予備）
              lv_enabled_flag,                --使用可能
              lv_detail_posting_allowed_flag, --転記の許可
              lv_start_date_active,           --有効開始日
              lv_end_date_active              --有効終了日
            FROM
              gl_code_combinations  --勘定科目組合せテーブル
            WHERE
              code_combination_id  =  xx03_error_checks_rec.code_combination_id
            ;
            --・データ存在時
            --以下の条件を全て満たすかをチェックします。満たさない場合は、エラー情
            --報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
            --・[2].使用可能(ENABLED_FLAG = ‘Y’)。
            --・[2].転記の許可(DETAIL_POSTING_ALLOWED_FLAG = ‘Y’)
            --・[2].有効開始日(START_DATE_ACTIVE)がNull  or　[2].有効開始日≦[1].GL記帳日。
            --・[2].有効終了日(END_DATE_ACTIVE)がNull or [2].有効終了日≧[1].GL記帳日。

            IF NOT ((lv_enabled_flag = 'Y') AND
                    (lv_detail_posting_allowed_flag = 'Y') AND
                    ((lv_start_date_active IS NULL ) OR (lv_start_date_active <= xx03_error_checks_rec.gl_date )) AND
                    ((lv_end_date_active   IS NULL ) OR (lv_end_date_active   >= xx03_error_checks_rec.gl_date ))) THEN

              lv_error_code   := 'APP-XX03-03014';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_INVALID_KEY';
              lt_tokeninfo(0).token_value := 'CCID';
              lt_tokeninfo(1).token_name := 'TOK_XX03_INVALID_VALUE';
              lt_tokeninfo(1).token_value := TO_CHAR(xx03_error_checks_rec.code_combination_id);
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error       );
              lt_tokeninfo.DELETE;
              --戻り値更新
              lv_ret_status := cv_status_error;
            ELSE
              --正常時、以下を実行しエラーチェックテーブルを更新します。
              UPDATE
                xx03_error_checks   --エラーチェックテーブル
              SET
                segment1  = lv_segment1,                    --セグメント1　（会社）
                segment2  = lv_segment2,                    --セグメント2　（部門）
                segment3  = lv_segment3,                    --セグメント3　（勘定科目）
                segment4  = lv_segment4,                    --セグメント4　（補助科目）
                segment5  = lv_segment5,                    --セグメント5　（相手先）
                segment6  = lv_segment6,                    --セグメント6　（事業区分）
                segment7  = lv_segment7,                    --セグメント7　（プロジェクト）
                segment8  = lv_segment8                     --セグメント8　（予備）
              WHERE
                   check_id     = xx03_error_checks_rec.check_id      --チェックID
              and  journal_id   = xx03_error_checks_rec.journal_id    --仕訳ID
              and  line_number  = xx03_error_checks_rec.line_number   --行番号
              ;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --・データ非存在時
              --  エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
              lv_error_code   := 'APP-XX03-03013';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_NOT_GET_KEY';
              lt_tokeninfo(0).token_value := 'CCID';
              lt_tokeninfo(1).token_name := 'TOK_XX03_NOT_GET_VALUE';

              lt_tokeninfo(1).token_value := TO_CHAR(xx03_error_checks_rec.code_combination_id);
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error       );
              lt_tokeninfo.DELETE;

              --戻り値更新
              lv_ret_status := cv_status_error;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;
        ELSE
            --「セグメント値チェック」
          BEGIN
            SELECT
              code_combination_id,          --CCID
              enabled_flag,                 --使用可能
              detail_posting_allowed_flag,  --転記の許可
              start_date_active,            --有効開始日
              end_date_active               --有効終了日
            INTO
              ln_code_combination_id,           --CCID
              lv_enabled_flag,                  --使用可能
              lv_detail_posting_allowed_flag,   --転記の許可
              lv_start_date_active,             --有効開始日
              lv_end_date_active                --有効終了日
            FROM
              gl_code_combinations  --勘定科目組合せテーブル
            WHERE
              chart_of_accounts_id  = ln_chart_of_accounts_id   --変数. 勘定体系ID
              and segment1 = xx03_error_checks_rec.segment1
              and segment2 = xx03_error_checks_rec.segment2
              and segment3 = xx03_error_checks_rec.segment3
              and segment4 = xx03_error_checks_rec.segment4
              and segment5 = xx03_error_checks_rec.segment5
              and segment6 = xx03_error_checks_rec.segment6
              and segment7 = xx03_error_checks_rec.segment7
              and segment8 = xx03_error_checks_rec.segment8
              ;
            --・データ存在時
            --  以下の条件を全て満たすかをチェックします。満たさない場合は、エラー情報テーブル出力
            --  サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
            --  ・[2]’.使用可能(ENABLED_FLAG = ‘Y’)。
            --  ・[2]’.転記の許可(DETAIL_POSTING_ALLOWD_FLAG = ‘Y’)
            --  ・[2]’.有効開始日(START_DATE_ACTIVE)がNull  or　[2]’.有効開始日≦[1].GL記帳日。
            --  ・[2]’.有効終了日(END_DATE_ACTIVE)がNull or [2]’.有効終了日≧[1].GL記帳日。

            IF NOT ((lv_enabled_flag = 'Y') AND
                    (lv_detail_posting_allowed_flag = 'Y') AND
                    ((lv_start_date_active IS NULL ) OR (lv_start_date_active <= xx03_error_checks_rec.gl_date )) AND
                    ((lv_end_date_active   IS NULL ) OR (lv_end_date_active   >= xx03_error_checks_rec.gl_date ))) THEN

              lv_error_code   := 'APP-XX03-03014';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_INVALID_KEY';
              lt_tokeninfo(0).token_value := 'CCID';
              lt_tokeninfo(1).token_name := 'TOK_XX03_INVALID_VALUE';
              lt_tokeninfo(1).token_value := TO_CHAR(ln_code_combination_id);--取得した方を表示
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error       );
              lt_tokeninfo.DELETE;

              --戻り値更新
              lv_ret_status := cv_status_error;
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --・データ非存在時
              --  次レコードを処理します。
              NULL;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;

        END IF;

      EXCEPTION
        WHEN local_continue THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR
            (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
      END;

    END LOOP ccid_check_loop;

    --カーソルのクローズ
    CLOSE xx03_error_checks_cur;
--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END ccid_check;
--
  /**********************************************************************************
   * Procedure Name   : period_check
   * Description      : GL会計期間チェック
   ***********************************************************************************/
  FUNCTION period_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.period_check'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ln_application_id               gl_period_statuses.application_id%TYPE;     --アプリケーションID
    ln_set_of_books_id              gl_period_statuses.set_of_books_id%TYPE;    --帳簿ID
    xx03_error_checks_rec           xx03_error_checks_cur%ROWTYPE;              --エラーチェックテーブルレコード

    lv_periond_name                 gl_period_statuses.period_name%TYPE;        --会計期間名
    lv_closing_status               gl_period_statuses.closing_status%TYPE;     --クロージングステータス

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値


    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    local_continue       EXCEPTION;
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  GLアプリケーションID取得
    ln_application_id := xx03_application_pkg.get_application_id_f('SQLGL') ;

    --3.  帳簿ID取得
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;

    --4.エラーチェックテーブル読み込み
     OPEN xx03_error_checks_cur(
        in_check_id         -- 1.チェックID
    );

    <<period_check_loop>>
    LOOP
      FETCH xx03_error_checks_cur INTO xx03_error_checks_rec;
      EXIT WHEN xx03_error_checks_cur%NOTFOUND;

      BEGIN
        --1)[1].GL会計期間がNULLであった場合
        --「GL記帳日の会計期間設定と会計期間のステータスチェック」を実行します。
        --  以外は
        --「会計期間のステータスチェック」を実行します。

        IF xx03_error_checks_rec.period_name is NULL THEN

          --「GL記帳日の会計期間設定と会計期間のステータスチェック」

          --1)GL記帳日チェック
          --  GL記帳日がNULLの場合、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エ
          --  ラー情報テーブルを出力します。
          IF xx03_error_checks_rec.gl_date IS NULL THEN
            lv_error_code   := 'APP-XX03-03042';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error       );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
            --次レコードを処理します。
            RAISE local_continue;
          END IF;

          --1)GL_会計期間ステータステーブルを取得します。
          BEGIN
            SELECT
            period_name,                --会計期間名
            closing_status              --クロージングステータス
            INTO
            lv_periond_name,
            lv_closing_status
            FROM  gl_period_statuses
            WHERE
                application_id          =  ln_application_id
            and set_of_books_id         =  ln_set_of_books_id
            and start_date              <= xx03_error_checks_rec.gl_date
            and end_date                >= xx03_error_checks_rec.gl_date
            and adjustment_period_flag  !='Y'  -- 調整期間ではない。
            ;

            --データ存在時
            --以下の条件を全て満たすかをチェックします。満たさない場合は、エラー情報テーブル出力サブ関数
            --(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
            --・変数.クロージングステータス = オープン(‘O’) or先日付入力可能(‘F’)

            IF NOT  ( lv_closing_status in ('O','F') ) THEN
              lv_error_code   := 'APP-XX03-03016';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_PERIOD_NAME';
              lt_tokeninfo(0).token_value := lv_periond_name;
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --戻り値更新
              lv_ret_status := cv_status_error;
              --次レコードを処理します。
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              --・データ非存在時
              --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
              lv_error_code   := 'APP-XX03-03015';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_GL_DATE';
              lt_tokeninfo(0).token_value := TO_CHAR(xx03_error_checks_rec.gl_date,'YYYY/MM/DD');

              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --戻り値更新
              lv_ret_status := cv_status_error;
              --次レコードを処理します。
              RAISE local_continue;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;
        ELSE
          --「会計期間のステータスチェック」を実行します。
          --1)GL_会計期間ステータステーブルを取得します。
          BEGIN
            SELECT
            closing_status              --クロージングステータス
            INTO
            lv_closing_status
            FROM  gl_period_statuses
            WHERE
                application_id          =  ln_application_id
            and set_of_books_id         =  ln_set_of_books_id
            and period_name             =   xx03_error_checks_rec.period_name
            ;

            --データ存在時
            --以下の条件を全て満たすかをチェックします。満たさない場合は、エラー情報テーブル出力サブ関数
            --(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
            --・変数.クロージングステータス = オープン(‘O’) or先日付入力可能(‘F’)

            IF NOT  ( lv_closing_status in ('O','F') ) THEN
              lv_error_code   := 'APP-XX03-03016';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_PERIOD_NAME';
              lt_tokeninfo(0).token_value := xx03_error_checks_rec.period_name;
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --戻り値更新
              lv_ret_status := cv_status_error;
              --次レコードを処理します。
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --・データ非存在時
              --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
              lv_error_code   := 'APP-XX03-03017';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_PERIOD_NAME';
              lt_tokeninfo(0).token_value := xx03_error_checks_rec.period_name;

              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --戻り値更新
              lv_ret_status := cv_status_error;
              --次レコードを処理します。
              RAISE local_continue;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;
        END IF;
      EXCEPTION
      WHEN local_continue THEN
          NULL;
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR
          (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
      END;

    END LOOP period_check_loop;

    --カーソルのクローズ
    CLOSE xx03_error_checks_cur;

--
    RETURN lv_ret_status;
--

  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END period_check;
--
  /**********************************************************************************
   * Procedure Name   : aff_dff_check
   * Description      : AFF・DFFチェック
   ***********************************************************************************/
  FUNCTION aff_dff_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.aff_dff_check'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
-- Ver11.5.10.2.8 Add Start
    --メッセージ
    cv_msg_cust_stop_err            CONSTANT VARCHAR2(30) := 'APP-XX03-03090';  --中止顧客チェックエラーメッセージ
    --プロファイル
    cv_prof_aff3_change             CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_CHANGE';  --XXCOK:勘定科目_仮払金（釣銭）
    --トークン
    cv_tkn_cust_num                 CONSTANT VARCHAR2(30) := 'TOK_XX03_CUST_NUM';   --顧客コード
    --固定値
    cv_cust_status_stop             CONSTANT VARCHAR2(2)  := '90';              --顧客ステータス：90(中止決裁済)
    --変数
    lt_account_change               xx03_companies_v.flex_value%TYPE;           --勘定科目_仮払金（釣銭）
-- Ver11.5.10.2.8 Add End
    ln_set_of_books_id              gl_period_statuses.set_of_books_id%TYPE;    --帳簿ID
    xx03_error_checks_rec           xx03_error_checks_cur%ROWTYPE;              --エラーチェックテーブルレコード

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

    lv_is_accounts_exists           boolean;                                    --勘定科目存在フラグ(TRUE:存在、FALSE:以外)

    ln_set_of_books_name            fnd_descr_flex_col_usage_vl.descriptive_flexfield_name%TYPE;
                                                                                --帳簿名
    ln_errbuf                       VARCHAR2(5000);                             --エラーバッファ
    ln_errmsg                       VARCHAR2(5000);                             --エラーメッセージ
    ln_retcode                      VARCHAR2(1);                                --リターンコード

    ln_application_id               gl_period_statuses.application_id%TYPE;     --アプリケーションID



    --GL会計帳簿
    CURSOR gl_sets_of_books_cur(
        in_set_of_books_id  IN  gl_sets_of_books.set_of_books_id%TYPE   -- 1.(帳簿ID)
    ) IS
      SELECT
        a.*
      FROM gl_sets_of_books a
      WHERE
          a.set_of_books_id = in_set_of_books_id
      ;

    gl_sets_of_books_rec            gl_sets_of_books_cur%ROWTYPE;             --テーブルレコード

    --会社マスタ
    CURSOR xx03_companies_v_cur(
        iv_flex_value       IN  xx03_companies_v.flex_value%TYPE,   -- 1.(会社)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM xx03_companies_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_companies_v_rec            xx03_companies_v_cur%ROWTYPE;             --テーブルレコード

    --勘定科目マスタ
    CURSOR xx03_accounts_v_cur(
        iv_flex_value       IN  xx03_accounts_v.flex_value%TYPE,    -- 1.(会社)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM xx03_accounts_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      ;

    xx03_accounts_v_rec           xx03_accounts_v_cur%ROWTYPE;              --テーブルレコード

    --部門マスタ
    CURSOR xx03_departments_v_cur(
        iv_flex_value       IN  xx03_departments_v.flex_value%TYPE, -- 1.(部門)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM  xx03_departments_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_departments_v_rec            xx03_departments_v_cur%ROWTYPE;             --テーブルレコード

    --補助科目マスタ
    CURSOR xx03_sub_accounts_v_cur(
        iv_flex_value       IN  xx03_sub_accounts_v.flex_value%TYPE,-- 1.(補助科目)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE,     -- 2.GL記帳日
        iv_segment3         IN  xx03_error_checks.segment3%TYPE     -- 3.勘定科目
    ) IS
      SELECT
        a.*
      FROM xx03_sub_accounts_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      AND a.parent_flex_value_low = iv_segment3
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;
      xx03_sub_accounts_v_rec           xx03_sub_accounts_v_cur%ROWTYPE;              --テーブルレコード

    --相手先マスタ
    CURSOR xx03_partners_v_cur(
        iv_flex_value       IN  xx03_partners_v.flex_value%TYPE,    -- 1.(相手先)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM xx03_partners_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_partners_v_rec           xx03_partners_v_cur%ROWTYPE;              --テーブルレコード

    --事業区分マスタ
    CURSOR xx03_business_types_v_cur(
        iv_flex_value       IN  xx03_business_types_v.flex_value%TYPE,    -- 1.(事業区分)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE            -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM xx03_business_types_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_business_types_v_rec           xx03_business_types_v_cur%ROWTYPE;              --テーブルレコード

    --プロジェクトマスタ
    CURSOR xx03_projects_v_cur(
        iv_flex_value       IN  xx03_projects_v.flex_value%TYPE,    -- 1.(プロジェクト)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM xx03_projects_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_projects_v_rec           xx03_projects_v_cur%ROWTYPE;              --テーブルレコード

    --予備マスタ
    CURSOR xx03_futures_v_cur(
        iv_flex_value       IN  xx03_futures_v.flex_value%TYPE,     -- 1.(予備)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL記帳日
    ) IS
      SELECT
        a.*
      FROM xx03_futures_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_futures_v_rec            xx03_futures_v_cur%ROWTYPE;             --テーブルレコード

  --税区分マスタ
    CURSOR xx03_tax_codes_v_cur(
        -- Ver11.5.10.1.6 2005/12/15 Change Start
        --iv_name             IN  xx03_tax_codes_v.name%TYPE,           -- 1.税区分
        --in_set_of_books_id  IN  xx03_tax_codes_v.set_of_books_id%TYPE -- 2.帳簿ID
        iv_name             IN  xx03_tax_codes_v.name%TYPE,           -- 1.税区分
        in_set_of_books_id  IN  xx03_tax_codes_v.set_of_books_id%TYPE,-- 2.帳簿ID
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE        -- 3.GL記帳日
        -- Ver11.5.10.1.6 2005/12/15 Change End
    ) IS
      SELECT
        a.*
      FROM xx03_tax_codes_v a
      WHERE
          a.name = iv_name
      AND a.set_of_books_id   = in_set_of_books_id
      AND a.enabled_flag      = 'Y'
      -- Ver11.5.10.1.6 2005/12/15 Add Start
      AND (a.start_date    IS NULL or a.start_date     <= id_gl_date )
      AND (a.inactive_date IS NULL or a.inactive_date  >= id_gl_date )
      -- Ver11.5.10.1.6 2005/12/15 Add End
      ;

    xx03_tax_codes_v_rec          xx03_tax_codes_v_cur%ROWTYPE;             --テーブルレコード

  --増減事由マスタ
    CURSOR xx03_incr_decr_reasons_v_cur(
        iv_ffl_flex_value         IN  xx03_incr_decr_reasons_v.ffl_flex_value%TYPE  -- 1.増減事由
    ) IS
      SELECT
        a.*
      FROM xx03_incr_decr_reasons_v a
      WHERE
          a.ffl_flex_value = iv_ffl_flex_value
      AND a.enabled_flag      = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND a.summary_flag      = 'N'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_incr_decr_reasons_v_rec    xx03_incr_decr_reasons_v_cur%ROWTYPE;     --テーブルレコード

  --CF組合せマスタ
    CURSOR xx03_cf_combinations_cur(
        iv_account_code           IN  xx03_error_checks.segment3%TYPE,              -- 1.勘定科目
        iv_incr_decr_reason_code  IN  xx03_error_checks.incr_decr_reason_code%TYPE, -- 2.増減事由
        id_gl_date                IN  xx03_error_checks.gl_date%TYPE                -- 3.GL記帳日
      ) IS
        SELECT
        a.*
      FROM xx03_cf_combinations a
      WHERE
          a.account_code = iv_account_code
-- 変更 1.7 BEGIN
--      AND a.incr_decr_reason_code = iv_incr_decr_reason_code
      AND NVL(a.incr_decr_reason_code, '#####') = NVL(iv_incr_decr_reason_code, '#####')
-- 変更 1.7 END
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6C 2006/01/16 Add Start
      AND a.set_of_books_id = xx00_profile_pkg.value ('GL_SET_OF_BKS_ID')
      -- Ver11.5.10.1.6C 2006/01/16 Add End
      ;

    xx03_cf_combinations_rec    xx03_cf_combinations_cur%ROWTYPE;     --テーブルレコード

    --部門マスタ(起票部門検索用)
    CURSOR xx03_departments_v_cur2(
        iv_flex_value       IN  xx03_departments_v.flex_value%TYPE  -- 1.(部門)
    ) IS
      SELECT
        a.*
      FROM  xx03_departments_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.enabled_flag      = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND a.summary_flag      = 'N'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_departments_v_rec2   xx03_departments_v_cur2%ROWTYPE;      --テーブルレコード

    --ユーザマスタ
    CURSOR xx03_users_v_cur(
        iv_user_name      IN  xx03_error_checks.input_user%TYPE -- 1.伝票入力者
    ) IS
      SELECT
        a.*
      FROM  xx03_users_v a
      WHERE
          a.user_name = iv_user_name
--      AND a.enabled_flag      = 'Y'
      ;

    xx03_users_v_rec    xx03_users_v_cur%ROWTYPE;     --テーブルレコード

    --値セット取得
    CURSOR fnd_descr_flex_col_cur(
        in_application_id           IN  fnd_descr_flex_col_usage_vl.application_id%TYPE,                -- 1.アプリケーションID
        iv_descriptive_flex_context IN  fnd_descr_flex_col_usage_vl.descriptive_flex_context_code%TYPE  -- 2.帳簿名
    ) IS
      SELECT
        a.*
      FROM  fnd_descr_flex_col_usage_vl a
      WHERE
            a.application_id                = in_application_id
        and a.descriptive_flexfield_name    = 'GL_JE_LINES'
        and a.descriptive_flex_context_code = iv_descriptive_flex_context
        and a.application_column_name       = 'ATTRIBUTE3'
      ;

    fnd_descr_flex_col_rec    fnd_descr_flex_col_cur%ROWTYPE;     --テーブルレコード

    --伝票番号最大長
    CURSOR fnd_flex_value_sets_cur(
        in_flex_value_set_id            IN  fnd_flex_value_sets.flex_value_set_id%TYPE  -- 1.伝票入力者
    ) IS
      SELECT
        a.*
      FROM  fnd_flex_value_sets a
      WHERE
          a.flex_value_set_id = in_flex_value_set_id
      ;

    fnd_flex_value_sets_rec   fnd_flex_value_sets_cur%ROWTYPE;      --テーブルレコード

    --通貨マスタ
    CURSOR fnd_currencies_cur(
        iv_currency_code      IN  fnd_currencies.currency_code%TYPE -- 1.通貨コード
      -- ver 11.5.10.2.6 Del Start
      ----2006/03/03 Ver11.5.10.1.6D Start
      -- ,id_gl_date            IN  DATE                              -- 2.GL記帳日
      ----2006/03/03 Ver11.5.10.1.6D End
      -- ver 11.5.10.2.6 Del End
    ) IS
      SELECT
        a.*
      FROM  fnd_currencies a
      WHERE
          a.currency_code = iv_currency_code
      AND a.enabled_flag      = 'Y'
      -- 2006/03/03 Ver11.5.10.1.6D add Start
      -- ver 11.5.10.2.6 Chg Start
      --AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      --AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      AND (a.start_date_active  IS NULL or a.start_date_active  <= TRUNC(SYSDATE) )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= TRUNC(SYSDATE) )
      -- ver 11.5.10.2.6 Chg End
      -- 2006/03/03 Ver11.5.10.1.6D add End
      ;

    fnd_currencies_rec    fnd_currencies_cur%ROWTYPE;     --テーブルレコード
-- Ver11.5.10.2.8 Add Start
    --顧客マスタ
    CURSOR cust_check_cur(
        it_segment5  IN  xx03_error_checks.segment5%TYPE   -- 1.segment5
    ) IS
      SELECT hp.duns_number_c       AS cust_status
      FROM   hz_cust_accounts hca
            ,hz_parties       hp
      WHERE  hca.party_id       = hp.party_id
      AND    hca.account_number = it_segment5
      ;
    --
    cust_check_rec  cust_check_cur%ROWTYPE;     --テーブルレコード
-- Ver11.5.10.2.8 Add End
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
  local_continue       EXCEPTION;


--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  帳簿ID取得
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;
-- Ver11.5.10.2.8 Add Start
    --    勘定科目_仮払金（釣銭）取得
    lt_account_change := xx00_profile_pkg.value (cv_prof_aff3_change) ;
-- Ver11.5.10.2.8 Add End
    --3.エラーチェックテーブル読み込み
     OPEN xx03_error_checks_cur(
        in_check_id         -- 1.チェックID
    );

    <<aff_dff_check_loop>>
    LOOP
      FETCH xx03_error_checks_cur INTO xx03_error_checks_rec;
      EXIT WHEN xx03_error_checks_cur%NOTFOUND;

      BEGIN
        -- 勘定科目存在フラグ初期化
        lv_is_accounts_exists := FALSE;

        --1)GL記帳日チェック
        --[1].GL記帳日がNULLの場合、エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報
        --テーブルを出力します。

        IF xx03_error_checks_rec.gl_date IS NULL THEN
          lv_error_code   := 'APP-XX03-03042';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
          --次レコードを処理します。
          RAISE local_continue;
        END IF;

        --2)AFFチェック(会社)
        --[1].segment1(会社)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment1 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT1');
--          lv_error_code   := 'APP-XX03-03018';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_companies_v_cur(
              xx03_error_checks_rec.segment1,         -- 1.[1].segment1(会社)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_companies_v_cur INTO xx03_companies_v_rec;

          IF xx03_companies_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT1');
--            lv_error_code   := 'APP-XX03-03018';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_companies_v_cur;
        END IF;

        --3)AFFチェック(勘定科目)
        --[1].segment3(勘定科目)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment3 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT3');
--          lv_error_code   := 'APP-XX03-03019';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_accounts_v_cur(
              xx03_error_checks_rec.segment3,         -- 1.[1].segment3(勘定科目)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_accounts_v_cur INTO xx03_accounts_v_rec;

          IF xx03_accounts_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT3');
--            lv_error_code   := 'APP-XX03-03019';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          ELSE
            --フラグ設定
            lv_is_accounts_exists := TRUE;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_accounts_v_cur;
        END IF;

        --4)AFFチェック(部門)
        --[1].segment2(部門)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment2 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT2');
--          lv_error_code   := 'APP-XX03-03020';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_departments_v_cur(
              xx03_error_checks_rec.segment2,         -- 1.[1].segment2(部門)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_departments_v_cur INTO xx03_departments_v_rec;

          IF xx03_departments_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT2');
--            lv_error_code   := 'APP-XX03-03020';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
-- 修正 1.1 BEGIN
--
            ELSE
              --先のAFFチェック(勘定科目)でマスタが取得できた場合、取得した、
              --xx03_accounts_v変数 (レコード型).attribute1(固定部門コード)が
              --nullでない場合以下をチェックします。xx03_accounts_v変数 (レコ
              --ード型).attribute1(固定部門コード)≠[1].segment2(部門)の場合、エ
              --ラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情
              --報テーブルを出力します。

              IF lv_is_accounts_exists AND xx03_accounts_v_rec.attribute1 IS NOT NULL  THEN
                IF xx03_accounts_v_rec.attribute1 != xx03_error_checks_rec.segment2 THEN
                  --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
                  lv_error_code   := 'APP-XX03-03026';
                  lt_tokeninfo.DELETE;
                  lt_tokeninfo(0).token_name := 'TOK_INVAQLID_FIX_DIV';
                  lt_tokeninfo(0).token_value := xx03_accounts_v_rec.attribute1;
-- 変更 1.11 BEGIN
                  lt_tokeninfo(1).token_name := 'TOK_XX03_SEGMENT_PROMPT';
                  lt_tokeninfo(1).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT2');
                  lt_tokeninfo(2).token_name := 'TOK_INVALID_DIV';
                  lt_tokeninfo(2).token_value := xx03_error_checks_rec.segment2;
--                  lt_tokeninfo(1).token_name := 'TOK_INVALID_DIV';
--                  lt_tokeninfo(1).token_value := xx03_error_checks_rec.segment2;
-- 変更 1.11 END
                  lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                      xx03_error_checks_rec.check_id    , --1.チェックID
                      xx03_error_checks_rec.journal_id  , --2.仕訳キー
                      xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                      xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                      lv_error_code   ,                   --5.エラーコード
                      lt_tokeninfo    ,                   --6.トークン情報
                      cv_status_error );
                  lt_tokeninfo.DELETE;
                  --戻り値更新
                  lv_ret_status := cv_status_error;
                END IF;
              END IF;
--
-- 修正 1.1 END
          END IF;
          --カーソルのクローズ
          CLOSE xx03_departments_v_cur;
        END IF;

        --5)AFFチェック(補助科目)
        --[1].segment4(補助科目)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment4 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT4');
--          lv_error_code   := 'APP-XX03-03021';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_sub_accounts_v_cur(
              xx03_error_checks_rec.segment4,         -- 1.[1].segment4(補助科目)
              xx03_error_checks_rec.gl_date,          -- 2.[1].GL記帳日
              xx03_error_checks_rec.segment3          -- 3.勘定科目
          );
          --読み込み

          FETCH xx03_sub_accounts_v_cur INTO xx03_sub_accounts_v_rec;

          IF xx03_sub_accounts_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT4');
--            lv_error_code   := 'APP-XX03-03021';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_sub_accounts_v_cur;
        END IF;

        --6)AFFチェック(相手先)
        --[1].segment5(相手先)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。


        IF xx03_error_checks_rec.segment5 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
--          lv_error_code   := 'APP-XX03-03022';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_partners_v_cur(
              xx03_error_checks_rec.segment5,         -- 1.[1].segment5(相手先)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_partners_v_cur INTO xx03_partners_v_rec;

          IF xx03_partners_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
--            lv_error_code   := 'APP-XX03-03022';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          ELSE
          --先のAFFチェック(勘定科目)でマスタが取得できた場合、取得した、
          --xx03_accounts_v変数 (レコード型).attribute2(相手先必須フラグ)
          --が’N’の場合、gl_sets_of_booksより集約相手先コードを取得し、
          --以下をチェックします。

-- 変更 1.5 BEGIN
--          相手先必須区分が'Y'の場合の条件も追加しますので、
--          xx03_accounts_v_rec.attribute2 = 'N'の条件をこのIF文
--          からは削除
--            IF lv_is_accounts_exists AND xx03_accounts_v_rec.attribute2 = 'N' THEN
            IF lv_is_accounts_exists THEN
-- 変更 1.5 END
              OPEN gl_sets_of_books_cur(
                  ln_set_of_books_id          -- 1.帳簿ID
              );
              --読み込み

              FETCH gl_sets_of_books_cur INTO gl_sets_of_books_rec;

              IF gl_sets_of_books_cur%NOTFOUND THEN
                lv_error_code   := 'APP-XX03-03027';
                lt_tokeninfo.DELETE;
-- 変更 1.11 BEGIN
                lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
                lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
-- 変更 1.11 END
                lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                    xx03_error_checks_rec.check_id    , --1.チェックID
                    xx03_error_checks_rec.journal_id  , --2.仕訳キー
                    xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                    xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                    lv_error_code   ,                   --5.エラーコード
                    lt_tokeninfo    ,                   --6.トークン情報
                    cv_status_error );
                lt_tokeninfo.DELETE;
                --戻り値更新
                lv_ret_status := cv_status_error;
              ELSE
                --[1].segment5(相手先) ≠ 変数. 集約相手先コードの場合、エラー情報
                --テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブ
                --ルを出力します。

-- 変更 1.5 BEGIN
--          相手先必須区分によって、条件式を変更
--                IF ( xx03_error_checks_rec.segment5 != gl_sets_of_books_rec.attribute1 ) OR
                IF ((xx03_accounts_v_rec.attribute2 = 'N' AND
                      xx03_error_checks_rec.segment5 != gl_sets_of_books_rec.attribute1)
                    OR
                    (xx03_accounts_v_rec.attribute2 = 'Y' AND
                      xx03_error_checks_rec.segment5 = gl_sets_of_books_rec.attribute1 )) OR
-- 変更 1.5 END
                   ( xx03_error_checks_rec.segment5 IS NULL     AND gl_sets_of_books_rec.attribute1 IS NOT NULL ) OR
                   ( xx03_error_checks_rec.segment5 IS NOT NULL AND gl_sets_of_books_rec.attribute1 IS NULL     ) THEN
                  lv_error_code   := 'APP-XX03-03027';
                  lt_tokeninfo.DELETE;
-- 変更 1.11 BEGIN
                  lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
                  lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
-- 変更 1.11 END
                  lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                      xx03_error_checks_rec.check_id    , --1.チェックID
                      xx03_error_checks_rec.journal_id  , --2.仕訳キー
                      xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                      xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                      lv_error_code   ,                   --5.エラーコード
                      lt_tokeninfo    ,                   --6.トークン情報
                      cv_status_error );
                  lt_tokeninfo.DELETE;
                  --戻り値更新
                  lv_ret_status := cv_status_error;
                END IF;
-- Ver11.5.10.2.8 Add Start
                --segment3(勘定科目)＝プロファイル「勘定科目_仮払金（釣銭）」の場合、
                --segment5(相手先)に設定された顧客をチェックします。
                IF ( lt_account_change IS NOT NULL AND xx03_error_checks_rec.segment3 = lt_account_change ) THEN
                  OPEN cust_check_cur(
                      xx03_error_checks_rec.segment5  -- 1.segment5
                  );
                  --読み込み
                  FETCH cust_check_cur INTO cust_check_rec;
                  --顧客ステータス＝'90'(中止決裁済)の場合、中止顧客として
                  --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、
                  --エラー情報テーブルを出力します。
                  IF cust_check_rec.cust_status = cv_cust_status_stop THEN
                    lv_error_code := cv_msg_cust_stop_err;
                    lt_tokeninfo.DELETE;
                    lt_tokeninfo(0).token_name  := cv_tkn_cust_num;                --TOK_XX03_CUST_NUM
                    lt_tokeninfo(0).token_value := xx03_error_checks_rec.segment5; --顧客コード
                    lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                       xx03_error_checks_rec.check_id    , --1.チェックID
                       xx03_error_checks_rec.journal_id  , --2.仕訳キー
                       xx03_error_checks_rec.line_number , --3.行番号
                       xx03_error_checks_rec.dr_cr       , --4.貸借区分
                       lv_error_code   ,                   --5.エラーコード
                       lt_tokeninfo    ,                   --6.トークン情報
                       cv_status_error );
                    lt_tokeninfo.DELETE;
                    --戻り値更新
                    lv_ret_status := cv_status_error;
                  END IF;
                  --カーソルのクローズ
                  CLOSE cust_check_cur;
                END IF;
-- Ver11.5.10.2.8 Add End
              END IF;
              --カーソルのクローズ
              CLOSE gl_sets_of_books_cur;

            END IF;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_partners_v_cur;
        END IF;

        --7)AFFチェック(事業区分)
        --[1].segment6(事業区分)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment6 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT6');
--          lv_error_code   := 'APP-XX03-03023';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_business_types_v_cur(
              xx03_error_checks_rec.segment6,         -- 1.[1].segment6(事業区分)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_business_types_v_cur INTO xx03_business_types_v_rec;

          IF xx03_business_types_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT6');
--            lv_error_code   := 'APP-XX03-03023';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_business_types_v_cur;
        END IF;

        --8)AFFチェック(プロジェクト)
        --[1].segment7(プロジェクト)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment7 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT7');
--          lv_error_code   := 'APP-XX03-03024';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_projects_v_cur(
              xx03_error_checks_rec.segment7,         -- 1.[1].segment7(プロジェクト)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_projects_v_cur INTO xx03_projects_v_rec;

          IF xx03_projects_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT7');
--            lv_error_code   := 'APP-XX03-03024';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_projects_v_cur;
        END IF;

        --9)AFFチェック(予備)
        --[1].segment8(予備)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.segment8 IS NULL THEN
-- 変更 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT8');
--          lv_error_code   := 'APP-XX03-03025';
--          lt_tokeninfo.DELETE;
-- 変更 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_futures_v_cur(
              xx03_error_checks_rec.segment8,         -- 1.[1].segment7(プロジェクト)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL記帳日
          );
          --読み込み

          FETCH xx03_futures_v_cur INTO xx03_futures_v_rec;

          IF xx03_futures_v_cur%NOTFOUND THEN
-- 変更 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT8');
--            lv_error_code   := 'APP-XX03-03025';
--            lt_tokeninfo.DELETE;
-- 変更 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_futures_v_cur;
        END IF;

        --10)DFFチェック(税区分)
        --[1].tax_code(税区分)がNULLの場合
        --先のAFFチェック(勘定科目)でマスタが取得できた場合、取得した、
        --xx03_accounts_v変数 (レコード型).attribute3(税区分必須区分)が
        --’9’(課税対象外)以外の場合は       --エラー情報テーブル出力サ
        --ブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.tax_code IS NULL THEN
-- 変更 1.6 BEGIN
--          IF lv_is_accounts_exists AND (xx03_accounts_v_rec.attribute3 != '9' or xx03_accounts_v_rec.attribute3 IS NULL)  THEN
          IF lv_is_accounts_exists AND
             (xx03_accounts_v_rec.attribute3 not in('1','9')
              or xx03_accounts_v_rec.attribute3 IS NULL)  THEN
-- 変更 1.6 END
            lv_error_code   := 'APP-XX03-03028';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_tax_codes_v_cur(
              -- Ver11.5.10.1.6 2005/12/15 Change Start
              --xx03_error_checks_rec.tax_code,         -- 1.[1].tax_code(税区分)
              --ln_set_of_books_id                      -- 2.帳簿ID
              xx03_error_checks_rec.tax_code,         -- 1.[1].tax_code(税区分)
              ln_set_of_books_id,                     -- 2.帳簿ID
              xx03_error_checks_rec.gl_date           -- 3.[1].GL記帳日
              -- Ver11.5.10.1.6 2005/12/15 Change End
          );
          --読み込み
          FETCH xx03_tax_codes_v_cur INTO xx03_tax_codes_v_rec;

          --・データ非存在時
          --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
          IF xx03_tax_codes_v_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03028';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          ELSE
            --・データ存在時
            --先のAFFチェック(勘定科目)でマスタが取得できた場合、
            --以下の条件を全て満たすかをチェックします。満たさない場合は、
            --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラ
            --ー情報テーブルを出力します。
-- コメント追加 1.6 BEGIN
            --・取得した、xx03_accounts_v変数 (レコード型).attribute3(税区分
            --必須区分)=’1’(仮受/仮払/対象外）の場合、全てOK
-- コメント追加 1.6 END
            --・取得した、xx03_accounts_v変数 (レコード型).attribute3(税区分
            --必須区分)=’2’(仮受の場合、[1].税区分= xx03_tax_codes_v変数 (レ
            --コード型).attribute2(課税集計区分)=’1’(課税売上)
            --・取得した、xx03_accounts_v変数 (レコード型).attribute3(税区分
            --必須区分)=’3’(仮払の場合、[1].税区分= xx03_tax_codes_v変数 (レ
            --コード型).attribute2(課税集計区分)=’2’(課税仕入)
-- コメント追加 1.6 BEGIN
            --・取得した、xx03_accounts_v変数 (レコード型).attribute3(税区分
            --必須区分)=’9’(対象外の場合、[1].税区分= xx03_tax_codes_v変数 (レ
            --コード型).attribute2(課税集計区分)=NULL
-- コメント追加 1.6 END
            IF lv_is_accounts_exists  THEN
-- 変更 1.6 BEGIN
--              IF NOT (( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 ='2' )) THEN
-- Ver11.5.10.1.5 2005/10/20 Modify Start
--              IF NOT (( xx03_accounts_v_rec.attribute3 = '1' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 ='2' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '9' AND xx03_tax_codes_v_rec.attribute2 IS NULL )) THEN
              IF (( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 ='2' ) OR
                  ( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 IS NULL ) OR
                  ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
                  ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 IS NULL ) OR
                  ( xx03_accounts_v_rec.attribute3 = '9' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
                  ( xx03_accounts_v_rec.attribute3 = '9' AND xx03_tax_codes_v_rec.attribute2 ='2' ) OR
                  ( xx03_accounts_v_rec.attribute3 IS NULL AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
                  ( xx03_accounts_v_rec.attribute3 IS NULL AND xx03_tax_codes_v_rec.attribute2 ='2' )) THEN
-- Ver11.5.10.1.5 2005/10/20 Modify End
-- 変更 1.6 END
                lv_error_code   := 'APP-XX03-03029';
                lt_tokeninfo.DELETE;
-- Ver11.5.10.1.5 2005/10/20 Add Start
                lt_tokeninfo(0).token_name := 'TOK_XX03_ACCT_CODE';
                lt_tokeninfo(0).token_value := xx03_accounts_v_rec.FLEX_VALUE;
                lt_tokeninfo(1).token_name := 'TOK_XX03_TAX_CODE';
                lt_tokeninfo(1).token_value := xx03_tax_codes_v_rec.name;
-- Ver11.5.10.1.5 2005/10/20 Add End
                lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                    xx03_error_checks_rec.check_id    , --1.チェックID
                    xx03_error_checks_rec.journal_id  , --2.仕訳キー
                    xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                    xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                    lv_error_code   ,                   --5.エラーコード
                    lt_tokeninfo    ,                   --6.トークン情報
                    cv_status_error );
                lt_tokeninfo.DELETE;
                --戻り値更新
                lv_ret_status := cv_status_error;
              END IF;
            END IF;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_tax_codes_v_cur;
        END IF;

        --11)DFFチェック(増減事由)
        --[1].incr_decr_reason_code(増減事由)がNULLの場合
        --チェックをスキップします。
        --[1].incr_decr_reason_code(増減事由)がNULL以外の場合
        --以下を実行します。
        IF xx03_error_checks_rec.incr_decr_reason_code IS NOT NULL THEN

          --マスタチェック
          --カーソルのオープン
          OPEN xx03_incr_decr_reasons_v_cur(
              xx03_error_checks_rec.incr_decr_reason_code   -- 1.[1].増減事由
          );
          --読み込み
          FETCH xx03_incr_decr_reasons_v_cur INTO xx03_incr_decr_reasons_v_rec;

          --・データ非存在時
          --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
          IF xx03_incr_decr_reasons_v_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03030';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          ELSE
            --・データ存在時
            --マスタチェック
            --カーソルのオープン
            OPEN xx03_cf_combinations_cur(
                xx03_error_checks_rec.segment3,                 -- 1.[1].勘定科目
                xx03_error_checks_rec.incr_decr_reason_code,    -- 2.[1].増減事由
                xx03_error_checks_rec.gl_date                   -- 3.[1].GL記帳日
            );
            --読み込み
            FETCH xx03_cf_combinations_cur INTO xx03_cf_combinations_rec;
            --・データ非存在時
            --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
            IF xx03_cf_combinations_cur%NOTFOUND THEN
              lv_error_code   := 'APP-XX03-03031';
              lt_tokeninfo.DELETE;
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.チェックID
                  xx03_error_checks_rec.journal_id  , --2.仕訳キー
                  xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                  xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                  lv_error_code   ,                   --5.エラーコード
                  lt_tokeninfo    ,                   --6.トークン情報
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --戻り値更新
              lv_ret_status := cv_status_error;
            END IF;
            --カーソルのクローズ
            CLOSE xx03_cf_combinations_cur;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_incr_decr_reasons_v_cur;
        -- Ver11.5.10.1.6C 2006/01/16 Add Start
        -- 増減事由がnullの場合は増減事由=NULLの組合せが存在するかのチェックが必要
        ELSE
          OPEN xx03_cf_combinations_cur(
              xx03_error_checks_rec.segment3,                 -- 1.[1].勘定科目
              xx03_error_checks_rec.incr_decr_reason_code,    -- 2.[1].増減事由
              xx03_error_checks_rec.gl_date                   -- 3.[1].GL記帳日
          );
          --読み込み
          FETCH xx03_cf_combinations_cur INTO xx03_cf_combinations_rec;
          --・データ非存在時
          --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
          IF xx03_cf_combinations_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03031';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_cf_combinations_cur;
         -- Ver11.5.10.1.6C 2006/01/16 Add End
        END IF;

        --12)DFFチェック(起票部門)
        --[1].input_department(起票部門)がNULLの場合、または以下の検索にてマスタ非存在時、エラー情報
        --テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.input_department IS NULL THEN
-- 変更 1.7 BEGIN
--          lv_error_code   := 'APP-XX03-03032';
--          lt_tokeninfo.DELETE;
--          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
--              xx03_error_checks_rec.check_id    , --1.チェックID
--              xx03_error_checks_rec.journal_id  , --2.仕訳キー
--              xx03_error_checks_rec.line_number , --3.行番号
--              lv_error_code   ,                   --4.エラーコード
--              lt_tokeninfo    ,                   --5.トークン情報
--              cv_status_error );
--          lt_tokeninfo.DELETE;
--          --戻り値更新
--          lv_ret_status := cv_status_error;
          NULL;
-- 変更 1.7 END
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_departments_v_cur2(
              xx03_error_checks_rec.input_department          -- 1.起票部門
          );
          --読み込み

          FETCH xx03_departments_v_cur2 INTO xx03_departments_v_rec2;

          IF xx03_departments_v_cur2%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03032';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_departments_v_cur2;
        END IF;

        --13)DFFチェック(伝票入力者)
        --[1].input_user(伝票入力者)がNULLの場合
        --チェックをスキップします。
        --[1]. input_user(伝票入力者)がNULL以外の場合
        --以下を実行します。

        IF xx03_error_checks_rec.input_user IS NOT NULL THEN
          --マスタチェック
          --カーソルのオープン
          OPEN xx03_users_v_cur(
              xx03_error_checks_rec.input_user          -- 1.伝票入力者
          );
          --読み込み

          FETCH xx03_users_v_cur INTO xx03_users_v_rec;

          IF xx03_users_v_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03033';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE xx03_users_v_cur;
        END IF;

        --14)DFFチェック(伝票番号)
        --[1].slip_number (伝票番号)がNULLの場合
        --チェックをスキップします。
        --[1].slip_number (伝票番号)がNULL以外の場合
        --以下を実行します。

        IF xx03_error_checks_rec.slip_number IS NOT NULL THEN

          --帳簿名の取得
          xx03_books_org_name_get_pkg.set_of_books_name(ln_errbuf,ln_retcode,ln_errmsg,ln_set_of_books_name,ln_set_of_books_id);

          --アプリケーションIDの取得
          ln_application_id := xx03_application_pkg.get_application_id_f('SQLGL');

          --マスタチェック
          --カーソルのオープン
          OPEN fnd_descr_flex_col_cur(
              ln_application_id,
              ln_set_of_books_name
          );

          --読み込み
          FETCH fnd_descr_flex_col_cur INTO fnd_descr_flex_col_rec;

          IF fnd_descr_flex_col_cur%NOTFOUND THEN
            NULL;
          ELSE
            --マスタチェック
            --カーソルのオープン
            OPEN fnd_flex_value_sets_cur(
                fnd_descr_flex_col_rec.flex_value_set_id  -- 1.セットID
            );

            --読み込み
            FETCH fnd_flex_value_sets_cur INTO fnd_flex_value_sets_rec;

            IF fnd_flex_value_sets_cur%NOTFOUND THEN
              NULL;
            ELSE
              --lengthb([1].slip_number (伝票番号))  >変数.値最大長のとき
              --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
              IF LENGTHB(xx03_error_checks_rec.slip_number) > TO_NUMBER(fnd_flex_value_sets_rec.maximum_size) THEN
                lv_error_code   := 'APP-XX03-03034';
                lt_tokeninfo.DELETE;
                lt_tokeninfo(0).token_name := 'TOK_XX03_LEN';
                lt_tokeninfo(0).token_value := fnd_flex_value_sets_rec.maximum_size;

                lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                    xx03_error_checks_rec.check_id    , --1.チェックID
                    xx03_error_checks_rec.journal_id  , --2.仕訳キー
                    xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                    xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                    lv_error_code   ,                   --5.エラーコード
                    lt_tokeninfo    ,                   --6.トークン情報
                    cv_status_error );
                lt_tokeninfo.DELETE;
                --戻り値更新
                lv_ret_status := cv_status_error;
              END IF;
            END IF;
            --カーソルのクローズ
            CLOSE fnd_flex_value_sets_cur;
          END IF;
          --カーソルのクローズ
          CLOSE fnd_descr_flex_col_cur;
        END IF;

        --15)通貨チェック
        --[1].currency_code(通貨)がNULLの場合、または以下の検索にてマスタ非存在時、
        --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF xx03_error_checks_rec.currency_code IS NULL THEN
          lv_error_code   := 'APP-XX03-03035';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.チェックID
              xx03_error_checks_rec.journal_id  , --2.仕訳キー
              xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
              xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          lt_tokeninfo.DELETE;
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --マスタチェック
          --カーソルのオープン
          OPEN fnd_currencies_cur(
              xx03_error_checks_rec.currency_code         -- 1.通貨コード
             -- ver 11.5.10.2.6 Del Start
             ---- 2006/03/03 Ver11.5.10.1.6D add Start
             --,xx03_error_checks_rec.gl_date               -- 2.[1].GL記帳日
             ---- 2006/03/03 Ver11.5.10.1.6D add END
             -- ver 11.5.10.2.6 Del End
          );
          --読み込み

          FETCH fnd_currencies_cur INTO fnd_currencies_rec;

          IF fnd_currencies_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03035';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.チェックID
                xx03_error_checks_rec.journal_id  , --2.仕訳キー
                xx03_error_checks_rec.line_number , --3.行番号
-- 追加 ver1.12 開始
                xx03_error_checks_rec.dr_cr       , --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            lt_tokeninfo.DELETE;
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
          --カーソルのクローズ
          CLOSE fnd_currencies_cur;
        END IF;

      EXCEPTION
        WHEN local_continue THEN
            NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR
            (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
      END;

    END LOOP aff_dff_check_loop;

    --カーソルのクローズ
    CLOSE xx03_error_checks_cur;

--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END aff_dff_check;
--
  /**********************************************************************************
   * Procedure Name   : balance_check
   * Description      : 仕訳バランスチェック
   ***********************************************************************************/
  FUNCTION balance_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.balance_check'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

    --バランスチェック用カーソル
    CURSOR balance_check_cur(
        in_check_id       IN  xx03_error_checks.check_id%TYPE   -- 1.チェックID
    ) IS
      SELECT
        a.check_id,                   --チェックID
        a.journal_id,                 --仕訳ID
        sum( NVL(a.entered_dr,0) ),   --借方金額
        sum( NVL(a.entered_cr,0) )    --貸方金額
      FROM
        xx03_error_checks a
      WHERE
        a.check_id  =  in_check_id
      GROUP BY
        a.check_id,    --チェックID
        a.journal_id  --仕訳ID
      HAVING
        sum(NVL(a.entered_dr,0 ))  !=sum(NVL(a.entered_cr,0) )
      ;

    balance_check_rec           balance_check_cur%ROWTYPE;              --テーブルレコード

--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    -- 2.バランスチェックカーソル読み込み
    OPEN balance_check_cur(
      in_check_id         -- 1.チェックID
    );

    <<balance_check_loop>>

    lt_tokeninfo.DELETE;

    LOOP
      FETCH balance_check_cur INTO balance_check_rec;
      EXIT WHEN balance_check_cur%NOTFOUND;
        --レコードが存在する間、エラー情報テーブル出力サブ関数
        --(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

        lv_error_code   := 'APP-XX03-03036';
        lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
            balance_check_rec.check_id    ,     --1.チェックID
            balance_check_rec.journal_id  ,     --2.仕訳キー
            0                             ,     --3.行番号
-- 追加 ver1.12 開始
            ' '             ,                   --4.貸借区分
-- 追加 ver1.12 終了
            lv_error_code   ,                   --5.エラーコード
            lt_tokeninfo    ,                   --6.トークン情報
            cv_status_error );

        --戻り値更新
        lv_ret_status := cv_status_error;

    END LOOP balance_check_loop;

    CLOSE balance_check_cur;

--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END balance_check;
--
  /**********************************************************************************
   * Procedure Name   : tax_range_check
   * Description      : 消費税額許容範囲チェック
   ***********************************************************************************/
  FUNCTION tax_range_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.tax_range_check'; -- プログラム名
-- 2015/03/24 Ver11.5.10.2.7 Add Start
    cv_comp_code_001  CONSTANT VARCHAR2(3) := '001';               -- 会社コード：001（本社）
-- 2015/03/24 Ver11.5.10.2.7 Add End
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ln_set_of_books_id              gl_tax_options.set_of_books_id%TYPE;    --帳簿ID
    ln_org_id                       gl_tax_options.org_id%TYPE;             --オルグID

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

-- 追加 1.9 BEGIN
    cn_curr_precision CONSTANT fnd_currencies.precision%TYPE := 2;              -- 通貨が取得できなかった場合の精度
-- 追加 1.9 END

-- 修正 1.2 BEGIN
--
    ln_check_id_old                 xx03_error_checks.check_id%TYPE;        -- 1.チェックID(ブレイクキー)
    ln_journal_id_old               xx03_error_checks.journal_id%TYPE;      -- 2.仕訳ID    (ブレイクキー)
--
-- 修正 1.2 END

    --税金オプション表検索

    CURSOR gl_tax_options_cur(
        ln_set_of_books_id        IN  gl_tax_options.set_of_books_id%TYPE,  -- 1.帳簿ID
        ln_org_id                 IN  gl_tax_options.org_id %TYPE           -- 2.オルグID
    ) IS
      SELECT
      a.attribute1,               --許容範囲率
      a.attribute2,               --許容範囲最大金額
      a.input_rounding_rule_code, --仮払端数処理規則
      a.output_rounding_rule_code --仮受端数処理規則
      FROM
        gl_tax_options a
      WHERE
          a.set_of_books_id       =  ln_set_of_books_id
      AND a.org_id                =  ln_org_id
      ;

    gl_tax_options_rec            gl_tax_options_cur%ROWTYPE;             --テーブルレコード

    --消費税額許容範囲チェック用カーソル
    CURSOR tax_range_check_cur(
        in_check_id                   IN  xx03_error_checks.check_id%TYPE,              -- 1.チェックID
        ln_set_of_books_id            IN  gl_tax_options.set_of_books_id%TYPE,          -- 2.帳簿ID
        iv_input_rounding_rule_code   IN  gl_tax_options.input_rounding_rule_code%TYPE, -- 3.仮払端数処理規則
        iv_output_rounding_rule_code  IN  gl_tax_options.output_rounding_rule_code%TYPE -- 4.仮受端数処理規則
    ) IS
    SELECT
      er.check_id,    --チェックid
      er.journal_id,  --仕訳id
-- 2015/03/24 Ver11.5.10.2.7 Add Start
--      er.segment1,    --会社コード
      cv_comp_code_001,  -- 会社コード：001（本社）
-- 2015/03/24 Ver11.5.10.2.7 Add End
      er.tax_code,    --税区分
    --
      sum(
        case
          when ac.attribute6 is null then --消費税科目区分がNULL(本科目行)
            case
-- 変更 1.10 BEGIN
--              when er.tax_code is null then
--                0 --税区分がnullは0として計算
              when nvl(tc.tax_rate,0) = 0 then
                0 --税率0%（非課税、不課税、免税、課税対象外）は0として計算
-- 変更 1.10 END
              else nvl(er.entered_dr,0) - nvl(er.entered_cr,0)
            end
          else 0 --税金行は加算せず。
        end ) sum_no_tax,   --税金行でない行の合計
    --
      sum(
        case
          when ac.attribute6 is null then --消費税科目区分がNULL(本科目行)
          case
-- 変更 1.10 BEGIN
--            when er.tax_code is null then 0 --税区分がnullは0として計算
            when nvl(tc.tax_rate,0) = 0 then 0 --税率0%は0として計算
-- 変更 1.10 END
            else
              case tc.attribute2    --税区分マスタの課税集計区分
                when  '1' then     --課税売上(仮受)
                  case  iv_output_rounding_rule_code --変数. 仮受端数処理規則 (output_rounding_rule_code)  --仮受端数処理規則
                    when  'N' then   --四捨五入
-- 変更 1.9 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- 変更 1.10 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      round(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      round(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- 変更 1.10 END
-- 変更 1.9 END
                    when  'U' then   --切り上げ
-- 変更 1.9 BEGIN
-- 変更 1.10 BEGIN
--                      sign( nvl(er.entered_dr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_dr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- 変更 1.10 END
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) ) -
-- 変更 1.10 BEGIN
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    (trunc((abs( nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) ) -
--                      sign( nvl(er.entered_cr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_cr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- 変更 1.10 END
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) )
-- 変更 1.10 BEGIN
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                      (trunc((abs( nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
-- 変更 1.10 END
-- 変更 1.9 END
                    else        --切り捨て(d)
-- 変更 1.9 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- 変更 1.10 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      trunc(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      trunc(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- 変更 1.10 END
-- 変更 1.9 END
                  end
                else          --課税仕入(仮払)
                  case  iv_input_rounding_rule_code --変数.仮払端数処理規則(input_rounding_rule_code)   --仮払端数処理規則
                    when  'N' then   --四捨五入
-- 変更 1.9 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- 変更 1.10 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      round(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      round(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- 変更 1.10 END
-- 変更 1.9 END
                    when  'U' then   --切り上げ
-- 変更 1.9 BEGIN
-- 変更 1.10 BEGIN
--                      sign( nvl(er.entered_dr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_dr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- 変更 1.10 END
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) ) -
-- 変更 1.10 BEGIN
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    (trunc((abs( nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) ) -
--                      sign( nvl(er.entered_cr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_cr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- 変更 1.10 END
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) )
-- 変更 1.10 BEGIN
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                      (trunc((abs( nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
-- 変更 1.10 END
-- 変更 1.9 END
                    else        --切り捨て(d)
-- 変更 1.9 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- 変更 1.10 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      trunc(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      trunc(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- 変更 1.10 END
-- 変更 1.9 END
                  end
              end
          end
      else 0 --税金行は対象外
      end
      ) sum_cal_tax,    --計算による税金行の合計
    --
      sum(
        case
          when ac.attribute6 is not null then   --消費税科目区分がNOT NULL(税金行)
            nvl(er.entered_dr,0) - nvl(er.entered_cr,0)
          else
            0       --税金行でなければ加算せず。
        end
      ) sum_tax     --税金行の合計
    FROM
      xx03_error_checks   er, --エラーチェックテーブル
      xx03_accounts_v     ac, --勘定科目マスタ
      xx03_tax_codes_v    tc, --税区分マスタ
      fnd_currencies      fc  --通貨マスタ
    WHERE
          er.check_id         = in_check_id
      and er.segment3         = ac.flex_value
      and er.tax_code         = tc.name (+)
-- 変更 1.10 BEGIN
--      and tc.set_of_books_id  = ln_set_of_books_id --変数.帳簿ID
      and tc.set_of_books_id (+)  = ln_set_of_books_id --変数.帳簿ID
-- 変更 1.10 END
      and er. currency_code   = fc. currency_code (+)
      -- Ver11.5.10.1.6 2005/12/15 Add Start
      and (tc.start_date    IS NULL or tc.start_date  <= er.gl_date )
      and (tc.inactive_date IS NULL or tc.inactive_date  >= er.gl_date)
      -- Ver11.5.10.1.6 2005/12/15 Add End
    GROUP BY
      er.check_id,  --チェックid
      er.journal_id,  --仕訳id
-- 2015/03/24 Ver11.5.10.2.7 Add Start
--      er.segment1,  --会社コード
      cv_comp_code_001,  -- 会社コード：001（本社）
-- 2015/03/24 Ver11.5.10.2.7 Add End
      er.tax_code   --税区分
-- 修正 1.2 BEGIN
--
    ORDER BY
      er.check_id,  --チェックid
      er.journal_id,--仕訳id
-- 2015/03/24 Ver11.5.10.2.7 Add Start
--      er.segment1,  --会社コード
      cv_comp_code_001,  -- 会社コード：001（本社）
-- 2015/03/24 Ver11.5.10.2.7 Add End
      er.tax_code   --税区分
--
-- 修正 1.2 END
    ;

    tax_range_check_rec           tax_range_check_cur%ROWTYPE;              --テーブルレコード

--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  帳簿ID取得
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;

    --3.  オルグID取得
    ln_org_id := xx00_profile_pkg.value ('ORG_ID') ;

    --4.  税金オプション表検索

    OPEN gl_tax_options_cur(
        ln_set_of_books_id,         -- 1.帳簿ID
        ln_org_id                   -- 2.オルグID
    );
    --読み込み
    FETCH gl_tax_options_cur INTO gl_tax_options_rec;
    IF gl_tax_options_cur%NOTFOUND THEN
      --戻り値更新
      lv_ret_status := cv_status_error;
      RETURN lv_ret_status;
    END IF;
    --カーソルのクローズ
    CLOSE gl_tax_options_cur;

    --5. 消費税許容範囲カーソル
    OPEN tax_range_check_cur(
        in_check_id,                                  -- 1.チェックID
        ln_set_of_books_id,                           -- 2.帳簿ID
        gl_tax_options_rec.input_rounding_rule_code,  -- 3.仮払端数処理規則
        gl_tax_options_rec.output_rounding_rule_code  -- 4.仮受端数処理規則
    );
-- 修正 1.2 BEGIN
--
    --エラー出力用ブレイクキー初期化
    ln_check_id_old        := NULL; -- 1.チェックID(ブレイクキー)
    ln_journal_id_old      := NULL; -- 2.仕訳ID    (ブレイクキー)
--
-- 修正 1.2 END

    <<tax_range_check_loop>>
    LOOP
      FETCH tax_range_check_cur INTO tax_range_check_rec;
      EXIT WHEN tax_range_check_cur%NOTFOUND;

      --a)許容範囲最大金額チェック
      --変数.差額 := ABS(sum_cal_tax  -  sum_tax )
      --変数.差額 >変数. 許容範囲最大金額の時
      --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

      IF ABS(tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) >
        TO_NUMBER(gl_tax_options_rec.attribute2) THEN

-- 修正 1.2 BEGIN
--
        IF (ln_check_id_old IS NULL AND ln_journal_id_old IS NULL ) OR
           (ln_check_id_old != tax_range_check_rec.check_id OR ln_journal_id_old != tax_range_check_rec.journal_id ) THEN
--
-- 修正 1.2 END

          lv_error_code   := 'APP-XX03-03037';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              tax_range_check_rec.check_id    , --1.チェックID
              tax_range_check_rec.journal_id  , --2.仕訳キー
              0 ,                               --3.行番号
-- 追加 ver1.12 開始
              ' '             ,                 --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                 --5.エラーコード
              lt_tokeninfo    ,                 --6.トークン情報
-- 修正 1.4 Begin
--              cv_status_error );
              cv_status_warning );
-- 修正 1.4 End
          lt_tokeninfo.DELETE;

          --戻り値更新
          lv_ret_status := cv_status_error;
-- 修正 1.2 BEGIN
--
          --ブレイクキー設定
          ln_check_id_old        :=tax_range_check_rec.check_id;    -- 1.チェックID(ブレイクキー)
          ln_journal_id_old      :=tax_range_check_rec.journal_id;  -- 2.仕訳ID    (ブレイクキー)
        END IF;
--
-- 修正 1.2 END

-- 変更 1.10 BEGIN
--      END IF;
      ELSE
-- 変更 1.10 END

      --b)許容範囲率チェック
      --変数.差額 := ABS(sum_cal_tax  -  sum_tax )
      --(変数.差額 / sum_no_tax ) * 100　>変数. 許容範囲率の時
      --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。

      IF tax_range_check_rec.sum_no_tax != 0 THEN
-- 変更 1.10 BEGIN
--        IF ( ABS (tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) / (tax_range_check_rec.sum_no_tax ) * 100 )
        IF ABS ( (tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) / (tax_range_check_rec.sum_no_tax ) * 100 )
-- 変更 1.10 END
           > TO_NUMBER(gl_tax_options_rec.attribute1) THEN
-- 修正 1.2 BEGIN
--
          IF (ln_check_id_old IS NULL AND ln_journal_id_old IS NULL) OR
             (ln_check_id_old != tax_range_check_rec.check_id OR ln_journal_id_old != tax_range_check_rec.journal_id ) THEN

            lv_error_code   := 'APP-XX03-03038';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                tax_range_check_rec.check_id    , --1.チェックID
                tax_range_check_rec.journal_id  , --2.仕訳キー
                0 ,                               --3.行番号
-- 追加 ver1.12 開始
                ' '             ,                 --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                 --5.エラーコード
                lt_tokeninfo    ,                 --6.トークン情報
-- 修正 1.4 Begin
--                cv_status_error );
                cv_status_warning );
-- 修正 1.4 End
            lt_tokeninfo.DELETE;

            --戻り値更新
            lv_ret_status := cv_status_error;
-- 修正 1.2 BEGIN
--
            --ブレイクキー設定
            ln_check_id_old        :=tax_range_check_rec.check_id;    -- 1.チェックID(ブレイクキー)
            ln_journal_id_old      :=tax_range_check_rec.journal_id;  -- 2.仕訳ID    (ブレイクキー)
          END IF;
--
-- 修正 1.2 END

        END IF;
      ELSE
-- 修正 1.2 BEGIN
--
-- 追加 1.10 BEGIN
       IF tax_range_check_rec.sum_tax != 0 THEN
-- 追加 1.10 END
        IF (ln_check_id_old IS NULL AND ln_journal_id_old IS NULL) OR
           (ln_check_id_old != tax_range_check_rec.check_id OR ln_journal_id_old != tax_range_check_rec.journal_id ) THEN

-- 追加 1.10 BEGIN
          lv_error_code   := 'APP-XX03-03043';
-- 追加 1.10 END
-- 削除 1.8 BEGIN
--          lv_error_code   := 'APP-XX03-03038';
-- 復元 1.10 BEGIN
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              tax_range_check_rec.check_id    , --1.チェックID
              tax_range_check_rec.journal_id  , --2.仕訳キー
              0 ,                               --3.行番号
-- 追加 ver1.12 開始
              ' '             ,                 --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                 --5.エラーコード
              lt_tokeninfo    ,                 --6.トークン情報
-- 修正 1.4 Begin
--              cv_status_error );
              cv_status_warning );
-- 修正 1.4 End
          lt_tokeninfo.DELETE;

          --戻り値更新
          lv_ret_status := cv_status_error;
-- 復元 1.10 END
-- 削除 1.8 END

          --ブレイクキー設定
          ln_check_id_old        :=tax_range_check_rec.check_id;    -- 1.チェックID(ブレイクキー)
          ln_journal_id_old      :=tax_range_check_rec.journal_id;  -- 2.仕訳ID    (ブレイクキー)

        END IF;
-- 追加 1.10 BEGIN
       END IF;
      END IF;
-- 追加 1.10 END
--
-- 修正 1.2 END
      END IF;

    END LOOP tax_range_check_loop;

    CLOSE tax_range_check_cur;

--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END tax_range_check;
--
  /**********************************************************************************
   * Procedure Name   : cf_balance_check
   * Description      : CFバランスチェック
   ***********************************************************************************/
  FUNCTION cf_balance_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.cf_balance_check'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ln_set_of_books_id              gl_tax_options.set_of_books_id%TYPE;        --帳簿ID

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

    --CFバランスチェック用カーソル
    CURSOR cf_balance_check_cur(
        in_check_id         IN  xx03_error_checks.check_id%TYPE,            -- 1.チェックID
        in_set_of_books_id  IN  xx03_cf_combinations.set_of_books_id%TYPE   -- 2.帳簿ID
    ) IS
    SELECT
      er.check_id,    --チェックID
      er.journal_id,   --仕訳ID
-- 修正 1.3 BEGIN
--
--      sum(NVL(er.entered_dr,0)  - NVL(er.entered_cr,0) ) money_diff,  -- ( 借方金額 -貸方金額 )
      sum(DECODE(cf.balance_check_flag,'Y',NVL(er.entered_dr,0)  - NVL(er.entered_cr,0),0 ) ) money_diff,  -- ( 借方金額 -貸方金額 )
--
-- 修正 1.3 END
      sum( decode( cf.cf_combination_id,null,-1,0) ) exist_check
    FROM
      xx03_error_checks er,
      xx03_cf_combinations cf
    WHERE
          er.check_id  =  in_check_id
      and er.segment3 = cf.account_code (+)
-- 変更 1.5 BEGIN
--      and er.incr_decr_reason_code = cf.incr_decr_reason_code(+)
      and nvl(er.incr_decr_reason_code, '#####') =
          nvl(cf.incr_decr_reason_code(+), '#####')
--      and er.incr_decr_reason_code is not null
-- 変更 1.5 END
      and cf.set_of_books_id (+) = in_set_of_books_id
-- 修正 1.3 BEGIN
--
--      and cf.balance_check_flag (+) ='Y'
--
-- 修正 1.3 END
    GROUP  BY
      check_id,    --チェックID
      journal_id   --仕訳ID
    ;

    cf_balance_check_rec            cf_balance_check_cur%ROWTYPE;             --テーブルレコード

--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  帳簿ID取得
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;

    -- 3.CFバランスチェックカーソル読み込み
    OPEN cf_balance_check_cur(
      in_check_id,        -- 1.チェックID,
      ln_set_of_books_id  --2.帳簿ID
    );

    <<cf_balance_check_loop>>
    lt_tokeninfo.DELETE;

    LOOP
      FETCH cf_balance_check_cur INTO cf_balance_check_rec;
      EXIT WHEN cf_balance_check_cur%NOTFOUND;
      --a)CF組合せマスタ存在チェック
      --exist_checkが負の値（ロジック変更）の場合、CF組合せマスタが取得できなかった
      --明細があったとしてエラー情報テーブル出力サブ関数(ins_error
      --_tbl)を呼び出し、エラー情報テーブルを出力します。

        IF cf_balance_check_rec.exist_check < 0 THEN
          lv_error_code   := 'APP-XX03-03039';
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              cf_balance_check_rec.check_id  ,    --1.チェックID
              cf_balance_check_rec.journal_id,    --2.仕訳キー
              0                             ,     --3.行番号
-- 追加 ver1.12 開始
              ' '             ,                   --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error );
          --戻り値更新
          lv_ret_status := cv_status_error;
        ELSE
          --exist_checkがnullでない場合で、sum(er.entered_dr  - er.entered_cr ) ≠0
          --の場合エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情
          --報テーブルを出力します。

          IF cf_balance_check_rec.money_diff != 0 THEN
            lv_error_code   := 'APP-XX03-03040';
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                cf_balance_check_rec.check_id  ,    --1.チェックID
                cf_balance_check_rec.journal_id,    --2.仕訳キー
                0                             ,     --3.行番号
-- 追加 ver1.12 開始
                ' '             ,                   --4.貸借区分
-- 追加 ver1.12 終了
                lv_error_code   ,                   --5.エラーコード
                lt_tokeninfo    ,                   --6.トークン情報
                cv_status_error );
            --戻り値更新
            lv_ret_status := cv_status_error;
          END IF;
        END IF;
    END LOOP cf_balance_check_loop;

    CLOSE cf_balance_check_cur;

    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END cf_balance_check;
--
  /**********************************************************************************
   * Procedure Name   : error_importance_check
   * Description      : エラー重大度チェック
   ***********************************************************************************/
  FUNCTION error_importance_check(
    in_check_id IN NUMBER) -- 1.チェックID
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.error_importance_check'; -- プログラム名

    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ln_set_of_books_id              gl_tax_options.set_of_books_id%TYPE;        --帳簿ID

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --トークン情報
    lv_error_code                   xx03_error_info.error_code%TYPE;            --エラーコード
    lv_ret                          xx03_error_info.status%TYPE;                --リターンステータス
    lv_ret_status                   xx03_error_info.status%TYPE;                --戻り値

    --エラー重大度カーソル１(対象チェックID分全件取得)
    CURSOR error_importance_check_cur1(
        in_check_id         IN  xx03_error_checks.check_id%TYPE           -- 1.チェックID
    ) IS
    SELECT
      count('X') all_recs
    FROM
      xx03_error_info er
    WHERE
      er.check_id  =  in_check_id
    ;
    error_importance_check_rec1           error_importance_check_cur1%ROWTYPE;  --テーブルレコード

    --エラー重大度カーソル２(Maxステータス取得)
    CURSOR error_importance_check_cur2(
        in_check_id         IN  xx03_error_checks.check_id%TYPE                 -- 1.チェックID
    ) IS
    SELECT
      MAX ( TO_NUMBER ( lk.meaning ) ) max_value,
      COUNT(lk.meaning) recs
    FROM
      xx03_error_info er,
      xx03_lookups_xx03_v lk
    WHERE
          er.check_id     =  in_check_id
      and er.status       = lk.lookup_code
      and lk.lookup_type = 'XX03_ERROR_IMPORTANCE'
    ;

    error_importance_check_rec2           error_importance_check_cur2%ROWTYPE;  --テーブルレコード

    --エラー重大度カーソル３(コード変換)
    CURSOR error_importance_check_cur3(
        in_meaning          IN  NUMBER                                          -- 1.エラー重大度
    ) IS
    SELECT
      lookup_code
    FROM
      xx03_lookups_xx03_v lk
    WHERE
        TO_NUMBER( lk.meaning )= in_meaning
    and lk.lookup_type ='XX03_ERROR_IMPORTANCE'
    ;
    error_importance_check_rec3           error_importance_check_cur3%ROWTYPE;  --テーブルレコード

--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --戻り値初期化
    lv_ret_status := cv_status_success ;--'S'

    -- 1. パラメータチェック
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    -- 2.エラー情報テーブル読込み
    OPEN error_importance_check_cur1(
        in_check_id
    );

    FETCH error_importance_check_cur1 INTO error_importance_check_rec1;

    IF error_importance_check_cur1%NOTFOUND THEN
      --変数.件数 = 0 の場合は、戻り値に’S’を設定し処理を終了します。
      --カーソルのクローズ
      CLOSE error_importance_check_cur1;
      RETURN cv_status_success;
    ELSE
      IF error_importance_check_rec1.all_recs = 0THEN
        --変数.件数 = 0 の場合は、戻り値に’S’を設定し処理を終了します。
        --カーソルのクローズ
        CLOSE error_importance_check_cur1;
        RETURN cv_status_success;
      END IF;
    END IF;
    --カーソルのクローズ
    CLOSE error_importance_check_cur1;

    --3.  エラー情報テーブル読込み（最大重大度エラー取得）
    OPEN error_importance_check_cur2(
        in_check_id
    );

    FETCH error_importance_check_cur2 INTO error_importance_check_rec2;

    IF error_importance_check_cur2%NOTFOUND THEN
      --変数.件数 = 0 の場合は、戻り値に’E’を設定し処理を終了します。(通常発生しない)
      --カーソルのクローズ
      CLOSE error_importance_check_cur2;
      RETURN cv_status_error;
    ELSE
      --変数.件数　≠変数.最大重大度件数の場合
      --LOOKUPテーブルから情報が取得できなかったとしてエラー情報テーブル出力サブ関数
      --(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
      IF ( error_importance_check_rec2.max_value IS NULL ) or
         ( error_importance_check_rec2.recs != error_importance_check_rec1.all_recs )THEN
          lv_error_code   := 'APP-XX03-03041';
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              in_check_id  ,                      --1.チェックID
              ' ',                                --2.仕訳キー
              0                             ,     --3.行番号
-- 追加 ver1.12 開始
              ' '             ,                   --4.貸借区分
-- 追加 ver1.12 終了
              lv_error_code   ,                   --5.エラーコード
              lt_tokeninfo    ,                   --6.トークン情報
              cv_status_error       );
        CLOSE error_importance_check_cur2;
        RETURN cv_status_error;
      END IF;
    END IF;

    --カーソルのクローズ
    CLOSE error_importance_check_cur2;

    --4.  LOOKUPテーブルによるエラーコード再変換
    OPEN error_importance_check_cur3(
        error_importance_check_rec2.max_value -- 1.エラー重大度
    );

    FETCH error_importance_check_cur3 INTO error_importance_check_rec3;

    IF error_importance_check_cur3%NOTFOUND THEN
      --変数.件数 = 0 の場合は、戻り値に’E’を設定し処理を終了します。(通常発生しない)
      --カーソルのクローズ
      CLOSE error_importance_check_cur3;
      RETURN cv_status_error;
    END IF;

    --カーソルのクローズ
    CLOSE error_importance_check_cur3;

    --5.  終了処理
    --関数戻り値に変数.エラーコードを返し処理を終了します。

    lv_ret_status := error_importance_check_rec3.lookup_code;
--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END error_importance_check;
--
  /**********************************************************************************
   * Procedure Name   : get_check_id
   * Description      : シーケンスより最新のチェックIDを取得します。
   ***********************************************************************************/
  FUNCTION get_check_id
  RETURN NUMBER IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.get_check_id'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    ln_check_id         NUMBER;
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    SELECT xx03_err_check_s.NEXTVAL
    INTO ln_check_id
    FROM dual;

    RETURN ln_check_id;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_check_id;
--
  /**********************************************************************************
   * Procedure Name   : ins_error_tbl
   * Description      : エラー情報テーブル出力関数
   ***********************************************************************************/
  FUNCTION ins_error_tbl(
    in_check_id     IN  NUMBER          , --1.チェックID
    iv_journal_id   IN  VARCHAR2        , --2.仕訳キー
    in_line_number  IN  NUMBER          , --3.行番号
-- 追加 ver1.12 開始
    iv_dr_cr        IN  VARCHAR2        , --4.貸借区分
-- 追加 ver1.12 終了
    iv_error_code   IN  VARCHAR2        , --5.エラーコード
    it_tokeninfo    IN  TOKENINFO_TTYPE , --6.トークン情報
    iv_status       IN  VARCHAR2        , --7.ステータス
    iv_application  IN  VARCHAR2 DEFAULT 'XX03')
  RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.ins_error_tbl'; -- プログラム名


    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    --共通関数用I/F項目
    iv_name           VARCHAR2(1000);
    iv_token_name1    VARCHAR2(1000);
    iv_token_value1   VARCHAR2(1000);
    iv_token_name2    VARCHAR2(1000);
    iv_token_value2   VARCHAR2(1000);
    iv_token_name3    VARCHAR2(1000);
    iv_token_value3   VARCHAR2(1000);
    iv_token_name4    VARCHAR2(1000);
    iv_token_value4   VARCHAR2(1000);
    iv_token_name5    VARCHAR2(1000);
    iv_token_value5   VARCHAR2(1000);
    iv_token_name6    VARCHAR2(1000);
    iv_token_value6   VARCHAR2(1000);
    iv_token_name7    VARCHAR2(1000);
    iv_token_value7   VARCHAR2(1000);
    iv_token_name8    VARCHAR2(1000);
    iv_token_value8   VARCHAR2(1000);
    iv_token_name9    VARCHAR2(1000);
    iv_token_value9   VARCHAR2(1000);
    iv_token_name10   VARCHAR2(1000);
    iv_token_value10  VARCHAR2(1000);

    lv_message        VARCHAR2(2000);

    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    chk_para_expt       EXCEPTION;

--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 1. パラメータチェック
    --  パラメータ.チェックIDがNULL or パラメータ.仕訳キーがNULL or パラメータ.行番号がNULLの場合
    --  はパラメータチェック例外(chk_para_expt)を呼び出します。

    IF (in_check_id IS NULL) OR (iv_journal_id IS NULL ) OR (in_line_number IS NULL) THEN
      RAISE chk_para_expt;
    END IF;

    -- 2. エラーメッセージ取得
    --  以下のパラメータをセットし、共通関数xx00_message_pkg.get_msgの戻り値よりエラーメッセージを
    --  変数.エラーメッセージに取得します。

    iv_name         :=iv_error_code ; --  引数.エラーコード

    IF it_tokeninfo.EXISTS(0) THEN
      iv_token_name1  := it_tokeninfo(0).token_name ; --トークン名
      iv_token_value1 := it_tokeninfo(0).token_value; --トークン値
    ELSE
      iv_token_name1  :=NULL;
      iv_token_value1 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(1) THEN
      iv_token_name2  := it_tokeninfo(1).token_name ; --トークン名
      iv_token_value2 := it_tokeninfo(1).token_value; --トークン値
    ELSE
      iv_token_name2  :=NULL;
      iv_token_value2 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(2) THEN
      iv_token_name3  := it_tokeninfo(2).token_name ; --トークン名
      iv_token_value3 := it_tokeninfo(2).token_value; --トークン値
    ELSE
      iv_token_name3  :=NULL;
      iv_token_value3 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(3) THEN
      iv_token_name4  := it_tokeninfo(3).token_name ; --トークン名
      iv_token_value4 := it_tokeninfo(3).token_value; --トークン値
    ELSE
      iv_token_name4  :=NULL;
      iv_token_value4 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(4) THEN
      iv_token_name5  := it_tokeninfo(4).token_name ; --トークン名
      iv_token_value5 := it_tokeninfo(4).token_value; --トークン値
    ELSE
      iv_token_name5  :=NULL;
      iv_token_value5 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(5) THEN
      iv_token_name6  := it_tokeninfo(5).token_name ; --トークン名
      iv_token_value6 := it_tokeninfo(5).token_value; --トークン値
    ELSE
      iv_token_name6  :=NULL;
      iv_token_value6 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(6) THEN
      iv_token_name7  := it_tokeninfo(6).token_name ; --トークン名
      iv_token_value7 := it_tokeninfo(6).token_value; --トークン値
    ELSE
      iv_token_name7  :=NULL;
      iv_token_value7 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(7) THEN
      iv_token_name8  := it_tokeninfo(7).token_name ; --トークン名
      iv_token_value8 := it_tokeninfo(7).token_value; --トークン値
    ELSE
      iv_token_name8  :=NULL;
      iv_token_value8 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(8) THEN
      iv_token_name9  := it_tokeninfo(8).token_name ; --トークン名
      iv_token_value9 := it_tokeninfo(8).token_value; --トークン値
    ELSE
      iv_token_name9  :=NULL;
      iv_token_value9 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(9) THEN
      iv_token_name10  := it_tokeninfo(9).token_name ;  --トークン名
      iv_token_value10 := it_tokeninfo(9).token_value;  --トークン値
    ELSE
      iv_token_name10  :=NULL;
      iv_token_value10 :=NULL;
    END IF;

    --共通関数

    lv_message := xx00_message_pkg.get_msg(
      iv_application    ,
      iv_name           ,
      iv_token_name1    ,
      iv_token_value1   ,
      iv_token_name2    ,
      iv_token_value2   ,
      iv_token_name3    ,
      iv_token_value3   ,
      iv_token_name4    ,
      iv_token_value4   ,
      iv_token_name5    ,
      iv_token_value5   ,
      iv_token_name6    ,
      iv_token_value6   ,
      iv_token_name7    ,
      iv_token_value7   ,
      iv_token_name8    ,
      iv_token_value8   ,
      iv_token_name9    ,
      iv_token_value9   ,
      iv_token_name10   ,
      iv_token_value10   );

    INSERT INTO xx03_error_info (
      check_id              ,
      journal_id            ,
      line_number           ,
-- 追加 ver1.12 開始
      dr_cr                 ,
-- 追加 ver1.12 終了
      error_code            ,
      error_message         ,
      status                ,
      created_by            ,
      creation_date         ,
      last_updated_by       ,
      last_update_date      ,
      last_update_login     ,
      request_id            ,
      program_application_id,
      program_id            ,
      program_update_date
    ) VALUES (
      in_check_id             ,-- check_id
      iv_journal_id           ,-- journal_id
      in_line_number          ,-- line_number
-- 追加 ver1.12 開始
      iv_dr_cr                ,-- dr_cr
-- 追加 ver1.12 終了
      iv_error_code           ,-- error_code
      lv_message              ,-- error_message
      iv_status               ,-- status
      xx00_global_pkg.created_by            ,-- created_by
      xx00_date_pkg.get_system_datetime_f   ,-- creation_date
      xx00_global_pkg.last_updated_by       ,-- last_updated_by
      xx00_date_pkg.get_system_datetime_f   ,-- last_update_date
      xx00_global_pkg.last_update_login     ,-- last_update_login
      xx00_global_pkg.conc_request_id       ,-- request_id
      xx00_global_pkg.prog_appl_id          ,-- program_application_id
      xx00_global_pkg.conc_program_id       ,-- program_id
      xx00_date_pkg.get_system_datetime_f    -- program_update_date
    );

    RETURN cv_status_success; --成功(S)
--
  EXCEPTION
    WHEN chk_para_expt THEN
      RETURN cv_status_param_err; --パラメータエラー(P)
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END ins_error_tbl;
--

END xx03_je_error_check_pkg;
/
