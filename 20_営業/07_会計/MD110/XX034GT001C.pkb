CREATE OR REPLACE PACKAGE BODY XX034GT001C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name     : XX034GT001C(body)
 * Description      : 承認済部門入力データをGL標準I/Fに転送後、部門入力転送日を更新する
 * MD.050           : 部門入力バッチ処理(GL)   OCSJ/BFAFIN/MD050/F602
 * MD.070           : 承認済仕訳の転送 OCSJ/BFAFIN/MD070/F602/05
 * Version          : 11.5.10.2.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_approval_slip_data 最終承認済仕訳データの取得 (A-1)
 *  ins_gl_interface       GLI/Fの更新 (A-2)
 *  upd_slip_data          GL転送済仕訳データの更新 (A-3)
 *  msg_output             結果出力 (A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/12/17   1.0            新規作成
 *  2005/03/11   1.1            不具合対応(No.393:ゼロ除算対応)
 *  2005/04/05   11.5.10.1.0    不具合対応(No.460:入力通貨金額ゼロ対応)
 *  2005/04/26   11.5.10.1.1    不具合対応(GL：税率0%の際の税金明細対応)
 *  2005/12/15   11.5.10.1.6    計上日において有効な税区分から、消費税行の各AFF値を
 *                              取得するように変更
 *  2006/01/17   11.5.10.1.6B   警告終了時は仕訳を計上せず、次のステージにも遷移
 *                              しないように修正
 *  2007/11/26   11.5.10.2.10   データ転送と転送済フラグ更新タイミングの修正
 *  2023/12/20   11.5.10.2.11   [E_本稼動_19496]対応 グループ会社統合対応
 *
 *****************************************************************************************/
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
--
--###########################  固定部 END   ############################
--
  -- *** グローバル定数 ***
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --結果出力用日付形式1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --結果出力用日付形式2
  cv_appr_status      CONSTANT  xx03_journal_slips.wf_status%TYPE := '80';  -- 経理承認済ステータス
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  chk_data_none_expt        EXCEPTION;              -- GL転送データ未取得エラー
  get_slip_type_name_expt   EXCEPTION;              -- 仕訳カテゴリ取得エラー
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface
   * Description      : GLI/Fの更新 (A-2)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    i_gl_if_rec       IN gl_interface%ROWTYPE,  -- 1.GLインターフェースレコード(IN)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- プログラム名
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- GL標準インターフェースへの挿入
    INSERT INTO gl_interface (
      status,
      set_of_books_id,
      accounting_date,
      currency_code,
      date_created,
      created_by,
      actual_flag,
      user_je_category_name,
      user_je_source_name,
      currency_conversion_date,
      user_currency_conversion_type,
      currency_conversion_rate,
      segment1,
      segment2,
      segment3,
      segment4,
      segment5,
      segment6,
      segment7,
      segment8,
      entered_dr,
      entered_cr,
      accounted_dr,
      accounted_cr,
      reference1,
      reference4,
      reference5,
      reference10,
      period_name,
      group_id,
      attribute1,
      attribute2,
      attribute3,
      attribute4,
      attribute5,
      attribute6,
      attribute7,
      attribute8,
      attribute9,
      attribute10,
-- Ver11.5.10.2.11 ADD START
      attribute15,
-- Ver11.5.10.2.11 ADD END
      context,
      jgzz_recon_ref
    )
    VALUES (
      i_gl_if_rec.status,
      i_gl_if_rec.set_of_books_id,
      i_gl_if_rec.accounting_date,
      i_gl_if_rec.currency_code,
      i_gl_if_rec.date_created,
      i_gl_if_rec.created_by,
      i_gl_if_rec.actual_flag,
      i_gl_if_rec.user_je_category_name,
      i_gl_if_rec.user_je_source_name,
      i_gl_if_rec.currency_conversion_date,
      i_gl_if_rec.user_currency_conversion_type,
      i_gl_if_rec.currency_conversion_rate,
      i_gl_if_rec.segment1,
      i_gl_if_rec.segment2,
      i_gl_if_rec.segment3,
      i_gl_if_rec.segment4,
      i_gl_if_rec.segment5,
      i_gl_if_rec.segment6,
      i_gl_if_rec.segment7,
      i_gl_if_rec.segment8,
      i_gl_if_rec.entered_dr,
      i_gl_if_rec.entered_cr,
      i_gl_if_rec.accounted_dr,
      i_gl_if_rec.accounted_cr,
      i_gl_if_rec.reference1,
      i_gl_if_rec.reference4,
      i_gl_if_rec.reference5,
      i_gl_if_rec.reference10,
      i_gl_if_rec.period_name,
      i_gl_if_rec.group_id,
      i_gl_if_rec.attribute1,
      i_gl_if_rec.attribute2,
      i_gl_if_rec.attribute3,
      i_gl_if_rec.attribute4,
      i_gl_if_rec.attribute5,
      i_gl_if_rec.attribute6,
      i_gl_if_rec.attribute7,
      i_gl_if_rec.attribute8,
      i_gl_if_rec.attribute9,
      i_gl_if_rec.attribute10,
-- Ver11.5.10.2.11 ADD START
      i_gl_if_rec.attribute15,
-- Ver11.5.10.2.11 ADD END
      i_gl_if_rec.context,
      i_gl_if_rec.jgzz_recon_ref
    );
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END ins_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : get_approval_slip_data
   * Description      : 最終承認済仕訳伝票データの取得(A-1)
   ***********************************************************************************/
  PROCEDURE get_approval_slip_data(
    iv_source         IN VARCHAR2,      -- 1.ソース名(IN)
    on_org_id         OUT NUMBER,       -- 2.オルグID(OUT)
    on_books_id       OUT NUMBER,       -- 3.会計帳簿ID(OUT)
    on_header_cnt     OUT NUMBER,       -- 4.ヘッダ件数(OUT)
    on_detail_cnt     OUT NUMBER,       -- 5.明細件数(OUT)
    od_upd_date       OUT DATE,         -- 6.更新日付(OUT)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_approval_slip_data'; -- プログラム名
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
    cv_us_rate_type     CONSTANT VARCHAR2(10) := 'User';
    cv_pay_lookup_type  CONSTANT xx03_ap_pay_groups_v.lookup_type%TYPE := 'PAY GROUP';
--
    -- *** ローカル変数 ***
    ln_created_by     NUMBER;         -- 作成者退避用
    lv_cur_lang       VARCHAR2(4);    -- 現在の言語コード
    lv_currency_code  xx03_journal_slips.invoice_currency_code%TYPE;
                                                         -- 機能通貨
    ln_precision      xx03_currencies_v.precision%TYPE;  -- 機能通貨の小数点以下桁数
    lv_slip_type      xx03_journal_slips.slip_type%TYPE; -- 伝票種別コード
--
    -- *** ローカル・カーソル ***
    CURSOR get_gl_trance_data_cur
    IS
      SELECT    xjs.journal_num             AS journal_num,
                xjs.slip_type               AS slip_type,
                xjs.invoice_currency_code   AS currency_code,
                xjs.exchange_rate           AS exchange_rate,
                DECODE(xjs.invoice_currency_code,
                  lv_currency_code,
                  NULL,
                  xjs.exchange_rate_type)   AS exchange_rate_type,
                DECODE(xjs.invoice_currency_code,
                  lv_currency_code,
                  NULL,
                  xjs.exchange_rate_type_name) AS exchange_rate_type_name,
                DECODE(xjs.invoice_currency_code,
                  lv_currency_code,
                  NULL,
                  xjs.gl_date)              AS exchange_date,
                xjs.ignore_rate_flag        AS ignore_rate_flag,
                xjs.description             AS description,
                xjs.entry_department        AS entry_department,
                xjs.entry_person_id         AS entry_person_id,
                xjs.orig_journal_num        AS orig_journal_num,
                xjs.period_name             AS period_name,
                xjs.gl_date                 AS gl_date,
                xjs.org_id                  AS org_id,
                xjs.set_of_books_id         AS set_of_books_id,
                xjsl.line_number            AS line_number,
                xjsl.entered_item_amount_dr AS entered_item_amount_dr,
                xjsl.entered_tax_amount_dr  AS entered_tax_amount_dr,
                xjsl.accounted_amount_dr    AS accounted_amount_dr,
                xjsl.entered_item_amount_cr AS entered_item_amount_cr,
                xjsl.entered_tax_amount_cr  AS entered_tax_amount_cr,
                xjsl.accounted_amount_cr    AS accounted_amount_cr,
                NVL(xjsl.tax_code_dr,
                    xjsl.tax_code_cr)       AS tax_code,
                xjsl.description            AS lines_description,
                xjsl.segment1               AS segment1,
                xjsl.segment2               AS segment2,
                xjsl.segment3               AS segment3,
                xjsl.segment4               AS segment4,
                xjsl.segment5               AS segment5,
                xjsl.segment6               AS segment6,
                xjsl.segment7               AS segment7,
                xjsl.segment8               AS segment8,
                xjsl.segment9               AS segment9,
                xjsl.segment10              AS segment10,
                xjsl.incr_decr_reason_code  AS incr_decr_reason_code,
                xjsl.recon_reference        AS recon_reference,
                xjsl.attribute1             AS attribute1,
                xjsl.attribute2             AS attribute2,
                xjsl.attribute3             AS attribute3,
                xjsl.attribute4             AS attribute4,
                xjsl.attribute5             AS attribute5,
                xjsl.attribute6             AS attribute6,
                xjsl.attribute7             AS attribute7,
                xjsl.attribute8             AS attribute8,
                xjsl.attribute9             AS attribute9,
                xjsl.attribute10            AS attribute10,
                xjsl.org_id                 AS lines_org_id,
                SYSDATE                     AS upd_date
                -- ver 11.5.10.2.10 Add Start
               ,xjs.journal_id AS journal_id
                -- ver 11.5.10.2.10 Add End
-- Ver11.5.10.2.11 ADD START
               ,xjs.drafting_company        AS drafting_company
-- Ver11.5.10.2.11 ADD END
      FROM      xx03_journal_slips xjs,
                xx03_journal_slip_lines xjsl
      WHERE     xjs.wf_status = cv_appr_status
      AND       xjs.gl_forword_date IS NULL
      AND       xjs.org_id = on_org_id
      AND       xjs.set_of_books_id = on_books_id
      AND       xjsl.journal_id = xjs.journal_id
      ORDER BY  xjs.journal_id
      -- ver 11.5.10.2.10 Chg Start
      --FOR UPDATE NOWAIT;
      FOR UPDATE OF xjs.journal_id NOWAIT;
      -- ver 11.5.10.2.10 Chg End
--
    -- *** ローカル・レコード ***
    -- GL仕訳伝票転送カーソルレコード
    get_gl_trance_data_rec get_gl_trance_data_cur%ROWTYPE;
--
    -- GL I/Fヘッダーレコード
    l_gl_if_item_rec  gl_interface%ROWTYPE;
    l_gl_if_tax_rec   gl_interface%ROWTYPE;
    l_gl_if_clear     gl_interface%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- オルグIDの取得
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    -- 会計帳簿IDの取得
    on_books_id := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
--
    -- 機能通貨の取得
    SELECT  gsob.currency_code AS currency_code,
            xcv.precision      AS precision
    INTO    lv_currency_code,
            ln_precision
    FROM    gl_sets_of_books gsob,
            xx03_currencies_v xcv
    WHERE   gsob.set_of_books_id = on_books_id
    AND     gsob.currency_code   = xcv.currency_code;
--
    xx00_file_pkg.log('org_id = ' || TO_CHAR(on_org_id));
    xx00_file_pkg.log('books_id = ' || TO_CHAR(on_books_id));
    xx00_file_pkg.log('currency_code = ' || lv_currency_code);
--
    -- GL仕訳伝票転送対象データ明細件数の取得
    SELECT COUNT(*)
    INTO   on_detail_cnt
    FROM   xx03_journal_slip_lines xjsl
    WHERE  xjsl.journal_id in (
      SELECT  xjs.journal_id
      FROM    xx03_journal_slips xjs
      WHERE   xjs.wf_status = cv_appr_status
      AND     xjs.gl_forword_date IS NULL
      AND     xjs.org_id = on_org_id
      AND     xjs.set_of_books_id = on_books_id);
--
    -- GL仕訳伝票転送対象データ件数の取得
    SELECT COUNT(*)
    INTO   on_header_cnt
    FROM   xx03_journal_slips xjs
    WHERE  xjs.wf_status = cv_appr_status
    AND    xjs.gl_forword_date IS NULL
    AND    xjs.org_id = on_org_id
    AND    xjs.set_of_books_id = on_books_id;
--
    -- GL仕訳伝票転送カーソルオープン
    OPEN get_gl_trance_data_cur;
    -- 変数初期化
    ln_created_by   := xx00_global_pkg.created_by;
    lv_cur_lang     := xx00_global_pkg.current_language;
    <<get_gl_trance_loop>>
    LOOP
      FETCH get_gl_trance_data_cur INTO get_gl_trance_data_rec;
--
      -- 0件判定
      IF (get_gl_trance_data_cur%NOTFOUND) THEN
        -- 件数判定
        IF on_header_cnt < 1 THEN
          RAISE chk_data_none_expt;
        END IF;
        EXIT get_gl_trance_loop;
      END IF;
      od_upd_date := get_gl_trance_data_rec.upd_date;
--
      -- 初期化
      l_gl_if_item_rec := l_gl_if_clear;
      l_gl_if_tax_rec  := l_gl_if_clear;
--
      -- 仕訳カテゴリ取得
      BEGIN
        SELECT gjcv.user_je_category_name
        INTO   l_gl_if_item_rec.user_je_category_name
        FROM   gl_je_categories_vl gjcv,
               xx03_slip_types_v   xstv
        WHERE  gjcv.je_category_name = xstv.attribute13
        AND    xstv.lookup_code      = get_gl_trance_data_rec.slip_type;
      EXCEPTION
        WHEN OTHERS THEN
          lv_slip_type := get_gl_trance_data_rec.slip_type;
          RAISE get_slip_type_name_expt;
      END;
--
      -- DFFコンテキスト(会計帳簿名)取得
      SELECT NAME
      INTO   l_gl_if_item_rec.context
      FROM   gl_sets_of_books
      WHERE  set_of_books_id = get_gl_trance_data_rec.set_of_books_id;
--
      -- グループID取得
      SELECT TO_NUMBER(attribute1)
      INTO   l_gl_if_item_rec.group_id
      FROM   gl_je_sources_tl
      WHERE  language = lv_cur_lang
      AND    user_je_source_name = iv_source;
--
      -- レート取得
      IF get_gl_trance_data_rec.currency_code <> lv_currency_code AND
         get_gl_trance_data_rec.exchange_rate_type = cv_us_rate_type THEN
        l_gl_if_item_rec.currency_conversion_rate := get_gl_trance_data_rec.exchange_rate;
      ELSE
        l_gl_if_item_rec.currency_conversion_rate := NULL;
      END IF;
--
      -- 伝票入力者名取得
      SELECT xuv.user_name
      INTO l_gl_if_item_rec.attribute5
      FROM  xx03_users_v xuv
      WHERE xuv.employee_id = get_gl_trance_data_rec.entry_person_id;
--
      -- GLインターフェースレコード型にセット(共通項目)
      l_gl_if_item_rec.status := 'NEW';
      l_gl_if_item_rec.set_of_books_id := get_gl_trance_data_rec.set_of_books_id;
      l_gl_if_item_rec.accounting_date := get_gl_trance_data_rec.gl_date;
      l_gl_if_item_rec.currency_code   := get_gl_trance_data_rec.currency_code;
      l_gl_if_item_rec.date_created    := get_gl_trance_data_rec.upd_date;
      l_gl_if_item_rec.created_by      := ln_created_by;
      l_gl_if_item_rec.actual_flag     := 'A';
      l_gl_if_item_rec.user_je_source_name := iv_source;
      l_gl_if_item_rec.currency_conversion_date := get_gl_trance_data_rec.exchange_date;
      l_gl_if_item_rec.user_currency_conversion_type := get_gl_trance_data_rec.exchange_rate_type_name;
      l_gl_if_item_rec.reference1  := NULL;
      l_gl_if_item_rec.reference4  := get_gl_trance_data_rec.journal_num;
      l_gl_if_item_rec.reference5  := get_gl_trance_data_rec.description;
      l_gl_if_item_rec.period_name := get_gl_trance_data_rec.period_name;
      l_gl_if_item_rec.attribute1  := get_gl_trance_data_rec.tax_code;
      l_gl_if_item_rec.attribute3  := get_gl_trance_data_rec.journal_num;
      l_gl_if_item_rec.attribute4  := get_gl_trance_data_rec.entry_department;
      l_gl_if_item_rec.attribute6  := get_gl_trance_data_rec.orig_journal_num;
-- Ver11.5.10.2.11 ADD START
      l_gl_if_item_rec.attribute15 := get_gl_trance_data_rec.drafting_company;
-- Ver11.5.10.2.11 ADD END
--
      l_gl_if_tax_rec := l_gl_if_item_rec;
--
      -- GLインターフェースレコード型にセット(本体行)
      l_gl_if_item_rec.segment1    := get_gl_trance_data_rec.segment1;
      l_gl_if_item_rec.segment2    := get_gl_trance_data_rec.segment2;
      l_gl_if_item_rec.segment3    := get_gl_trance_data_rec.segment3;
      l_gl_if_item_rec.segment4    := get_gl_trance_data_rec.segment4;
      l_gl_if_item_rec.segment5    := get_gl_trance_data_rec.segment5;
      l_gl_if_item_rec.segment6    := get_gl_trance_data_rec.segment6;
      l_gl_if_item_rec.segment7    := get_gl_trance_data_rec.segment7;
      l_gl_if_item_rec.segment8    := get_gl_trance_data_rec.segment8;
      l_gl_if_item_rec.entered_dr  := get_gl_trance_data_rec.entered_item_amount_dr;
      l_gl_if_item_rec.entered_cr  := get_gl_trance_data_rec.entered_item_amount_cr;
      IF get_gl_trance_data_rec.ignore_rate_flag = 'Y' THEN
        l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.entered_item_amount_dr
                                       * NVL(get_gl_trance_data_rec.exchange_rate,1);
        l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.entered_item_amount_cr
                                       * NVL(get_gl_trance_data_rec.exchange_rate,1);
      ELSE
-- ver 1.1 Change Start
--        l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.accounted_amount_dr
--                                       *(get_gl_trance_data_rec.entered_item_amount_dr
--                                       /(get_gl_trance_data_rec.entered_item_amount_dr
--                                        +get_gl_trance_data_rec.entered_tax_amount_dr));
--        l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.accounted_amount_cr
--                                       *(get_gl_trance_data_rec.entered_item_amount_cr
--                                       /(get_gl_trance_data_rec.entered_item_amount_cr
--                                        +get_gl_trance_data_rec.entered_tax_amount_cr));
        IF (  get_gl_trance_data_rec.entered_item_amount_dr
            + get_gl_trance_data_rec.entered_tax_amount_dr  ) = 0 THEN
-- ver 11.5.10.1.0 Change Start
--          l_gl_if_item_rec.accounted_dr := 0;
          l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.accounted_amount_dr;
-- ver 11.5.10.1.0 Change End
        ELSE
          l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.accounted_amount_dr
                                         *(get_gl_trance_data_rec.entered_item_amount_dr
                                         /(get_gl_trance_data_rec.entered_item_amount_dr
                                          +get_gl_trance_data_rec.entered_tax_amount_dr));
        END IF;
        IF (  get_gl_trance_data_rec.entered_item_amount_cr
            + get_gl_trance_data_rec.entered_tax_amount_cr  ) = 0 THEN
--ver 11.5.10.1.0 Change Start
--          l_gl_if_item_rec.accounted_cr := 0;
          l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.accounted_amount_cr;
--ver 11.5.10.1.0 Change End
        ELSE
          l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.accounted_amount_cr
                                         *(get_gl_trance_data_rec.entered_item_amount_cr
                                         /(get_gl_trance_data_rec.entered_item_amount_cr
                                          +get_gl_trance_data_rec.entered_tax_amount_cr));
        END IF;
-- ver 1.1 Change End
      END IF;
      l_gl_if_item_rec.accounted_dr   := ROUND(l_gl_if_item_rec.accounted_dr, ln_precision);
      l_gl_if_item_rec.accounted_cr   := ROUND(l_gl_if_item_rec.accounted_cr, ln_precision);
      l_gl_if_item_rec.reference10    := get_gl_trance_data_rec.lines_description;
      l_gl_if_item_rec.attribute2     := get_gl_trance_data_rec.incr_decr_reason_code;
      l_gl_if_item_rec.attribute7     := get_gl_trance_data_rec.attribute7;
      l_gl_if_item_rec.attribute8     := get_gl_trance_data_rec.attribute8;
      l_gl_if_item_rec.attribute9     := get_gl_trance_data_rec.attribute9;
      l_gl_if_item_rec.attribute10    := get_gl_trance_data_rec.attribute10;
      l_gl_if_item_rec.jgzz_recon_ref := get_gl_trance_data_rec.recon_reference;
--
      -- GLインターフェースレコード型にセット(消費税行)
      SELECT gcc.segment1 AS segment1,
             gcc.segment2 AS segment2,
             gcc.segment3 AS segment3,
             gcc.segment4 AS segment4,
             gcc.segment5 AS segment5,
             gcc.segment6 AS segment6,
             gcc.segment7 AS segment7,
             gcc.segment8 AS segment8
      INTO   l_gl_if_tax_rec.segment1,
             l_gl_if_tax_rec.segment2,
             l_gl_if_tax_rec.segment3,
             l_gl_if_tax_rec.segment4,
             l_gl_if_tax_rec.segment5,
             l_gl_if_tax_rec.segment6,
             l_gl_if_tax_rec.segment7,
             l_gl_if_tax_rec.segment8
      FROM   xx03_tax_codes_v xtcv,
             gl_code_combinations gcc
      WHERE  xtcv.name = get_gl_trance_data_rec.tax_code
      -- Ver11.5.10.1.6 2005/12/15 Add Start
      AND    get_gl_trance_data_rec.gl_date BETWEEN NVL(xtcv.start_date, TO_DATE('1000/01/01', 'YYYY/MM/DD')) 
      AND    NVL(xtcv.inactive_date, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
      -- Ver11.5.10.1.6 2005/12/15 Add End
      AND    xtcv.tax_code_combination_id = gcc.code_combination_id;
--
      l_gl_if_tax_rec.entered_dr     := get_gl_trance_data_rec.entered_tax_amount_dr;
      l_gl_if_tax_rec.entered_cr     := get_gl_trance_data_rec.entered_tax_amount_cr;
      l_gl_if_tax_rec.accounted_dr   := get_gl_trance_data_rec.accounted_amount_dr
                                      - l_gl_if_item_rec.accounted_dr;
      l_gl_if_tax_rec.accounted_cr   := get_gl_trance_data_rec.accounted_amount_cr
                                      - l_gl_if_item_rec.accounted_cr;
      l_gl_if_tax_rec.reference10    := NULL;
      l_gl_if_tax_rec.attribute2     := NULL;
      l_gl_if_tax_rec.attribute7     := NULL;
      l_gl_if_tax_rec.attribute8     := NULL;
      l_gl_if_tax_rec.attribute9     := NULL;
      l_gl_if_tax_rec.attribute10    := NULL;
      l_gl_if_tax_rec.jgzz_recon_ref := NULL;
--
      -- =======================================
      -- GLI/Fの更新 - 本体情報の登録 (A-2)
      -- =======================================
      ins_gl_interface(
        l_gl_if_item_rec,                         -- 1.GLインターフェースレコード(IN)
        lv_errbuf,      -- エラー・メッセージ           --# 固定 #
        lv_retcode,     -- リターン・コード             --# 固定 #
        lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- =======================================
      -- GLI/Fの更新 - 消費税情報の登録 (A-2)
      -- =======================================
      --2005.04.26 change start Ver11.5.10.1.1
      IF (l_gl_if_tax_rec.entered_dr IS NULL AND
        l_gl_if_tax_rec.entered_cr <> 0) OR
        (l_gl_if_tax_rec.entered_cr IS NULL AND
        l_gl_if_tax_rec.entered_dr <> 0) THEN
        ins_gl_interface(
          l_gl_if_tax_rec,                          -- 1.GLインターフェースレコード(IN)
          lv_errbuf,      -- エラー・メッセージ           --# 固定 #
          lv_retcode,     -- リターン・コード             --# 固定 #
          lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
      END IF;
      --2005.04.26 change end Ver11.5.10.1.1
--
      -- ver 11.5.10.2.10 Add Start
      -- 正常時処理
      IF (ov_retcode != xx00_common_pkg.set_status_error_f) AND
         (ov_retcode != xx00_common_pkg.set_status_warn_f ) THEN
        --仕訳伝票データの更新
        UPDATE  xx03_journal_slips xjs
        SET     xjs.gl_forword_date   = od_upd_date,
                xjs.last_update_date  = od_upd_date,
                xjs.last_updated_by   = xx00_global_pkg.user_id,
                xjs.last_update_login = xx00_global_pkg.last_update_login
        WHERE   xjs.journal_id = get_gl_trance_data_rec.journal_id
        ;
      END IF;
      -- ver 11.5.10.2.10 Add End
--
    END LOOP get_gl_trance_loop;
    CLOSE get_gl_trance_data_cur;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_data_none_expt THEN        --*** 転送処理対象データ未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01058'));           -- 転送処理対象データ未取得エラーメッセージ
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
    WHEN get_slip_type_name_expt THEN   --*** 仕訳カテゴリ取得エラー ***
      -- *** 任意で例外処理を記述する ****
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01060',             -- 仕訳カテゴリ取得エラーメッセージ
          'XX03_TOK_SLIP_TYPE',
          lv_slip_type));               -- 伝票種別コード
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      -- Ver11.5.10.1.6B Change Start
      --ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
      -- Ver11.5.10.1.6B Change End
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_approval_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_slip_data
   * Description      : GL転送済仕訳伝票データの更新 (A-3)
   ***********************************************************************************/
  PROCEDURE upd_slip_data(
    in_org_id         IN  NUMBER,       -- 1.オルグID(IN)
    in_books_id       IN  NUMBER,       -- 2.会計帳簿ID(IN)
    id_sysdate        IN  DATE,         -- 3.更新日付(IN)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_slip_data'; -- プログラム名
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --仕訳伝票データの更新
    UPDATE  xx03_journal_slips xjs
    SET     xjs.gl_forword_date   = id_sysdate,
            xjs.last_update_date  = id_sysdate,
            xjs.last_updated_by   = xx00_global_pkg.user_id,
            xjs.last_update_login = xx00_global_pkg.last_update_login
    WHERE   xjs.wf_status = cv_appr_status
    AND     xjs.gl_forword_date IS NULL
    AND     xjs.org_id = in_org_id
    AND     xjs.set_of_books_id = in_books_id;
--
    --ログ出力
    xx00_file_pkg.log('UPDATE table :xx03_journal_slips');
    xx00_file_pkg.log('org_id = '|| TO_CHAR(in_org_id));
    xx00_file_pkg.log('books_id = '|| TO_CHAR(in_books_id));
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : 結果出力 (A-4)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id     IN  NUMBER,       --  1.オルグID(IN)
    in_books_id   IN  NUMBER,       --  2.会計帳簿ID(IN)
    in_header_cnt IN  NUMBER,       --  3.ヘッダ件数(IN)
    in_detail_cnt IN  NUMBER,       --  4.明細件数(IN)
    iv_source     IN  VARCHAR2,     --  5.ソース名(IN)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'msg_output'; -- プログラム名
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
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- ヘッダー出力
    xx03_header_line_output_pkg.header_line_output_p('GL',    -- 会計帳簿名を表示する
      xx00_global_pkg.prog_appl_id,
      in_books_id,                        -- 会計帳簿ID
      in_org_id,                          -- オルグID
      xx00_global_pkg.conc_program_id,
      lv_errbuf,
      lv_retcode,
      lv_errmsg);
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- パラメータのログ出力
    xx00_file_pkg.output(' ');
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' || 
      iv_source);
    xx00_file_pkg.output(' ');
--
    -- 件数出力
    xx00_file_pkg.output(
    xx00_message_pkg.get_msg(
      'XX03',
      'APP-XX03-01059',             -- 承認済仕訳転送結果出力
      'XX03_TOK_HEAD_CNT',
      in_header_cnt,                -- GL転送件数(ヘッダ)
      'XX03_TOK_DETAIL_CNT',
      in_detail_cnt));              -- GL転送件数(明細)
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END msg_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     -- 1.ソース名
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
    ln_org_id         NUMBER(15,0);   -- オルグID
    ln_books_id       gl_sets_of_books.set_of_books_id%TYPE;  -- 会計帳簿ID
    ln_header_cnt     NUMBER;         -- ヘッダ件数
    ln_detail_cnt     NUMBER;         -- 明細件数
    ld_upd_date       DATE;           -- 更新日付
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =======================================
    -- 最終承認済仕訳データの取得(A-1)
    -- =======================================
    get_approval_slip_data(
      iv_source,          -- 1.ソース名(OUT)
      ln_org_id,          -- 2.オルグID(OUT)
      ln_books_id,        -- 3.会計帳簿ID(OUT)
      ln_header_cnt,      -- 4.ヘッダ件数(OUT)
      ln_detail_cnt,      -- 5.明細件数(OUT)
      ld_upd_date,        -- 6.更新日付(OUT)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(警告処理)
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSE
--
      -- ver 11.5.10.2.10 Del Start
      ---- =======================================
      ---- GL転送済仕訳データの更新 (A-3)
      ---- =======================================
      --upd_slip_data(
      --  ln_org_id,            -- 1.オルグID(IN)
      --  ln_books_id,          -- 2.会計帳簿ID(IN)
      --  ld_upd_date,          -- 2.更新日付(IN)
      --  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      --  lv_retcode,           -- リターン・コード             --# 固定 #
      --  lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      --IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --  --(エラー処理)
      --  RAISE global_process_expt;
      --END IF;
      -- ver 11.5.10.2.10 Del End
--
      -- =======================================
      -- 結果出力 (A-4)
      -- =======================================
      msg_output(
        ln_org_id,          --  1.チェックID(IN)
        ln_books_id,        --  2.会計帳簿ID(IN)
        ln_header_cnt,      --  3.ヘッダ件数(IN)
        ln_detail_cnt,      --  4.明細件数(IN)
        iv_source,          --  5.ソース名(IN)
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
    iv_source     IN  VARCHAR2)      -- 1.ソース名(IN)
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
    -- ===============================
    -- ログヘッダの出力
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_source,   -- 1.ソース名(IN)
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ログフッタの出力
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    -- Ver11.5.10.1.6B Change Start
    --IF (retcode = xx00_common_pkg.set_status_error_f) THEN
    IF (retcode != xx00_common_pkg.set_status_normal_f) THEN
    -- Ver11.5.10.1.6B Change End
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** 共通関数OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XX034GT001C;
/

