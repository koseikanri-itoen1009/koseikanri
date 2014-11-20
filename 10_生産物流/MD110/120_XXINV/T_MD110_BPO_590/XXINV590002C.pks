CREATE OR REPLACE PACKAGE xxinv590002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv590002c(spec)
 * Description      : OPM在庫会計期間クローズ
 * MD.050           : OPM在庫会計期間オープン(クローズ) T_MD050_BPO_590
 * MD.070           : OPM在庫会計期間クローズ(59B) T_MD070_BPO_59B
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/08/06    1.0   Y.Suzuki         新規作成
 *
 *****************************************************************************************/
--
  -- コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_sequence     IN     VARCHAR2,         -- シーケンスID
    iv_fiscal_year  IN     VARCHAR2,         -- 会計年度
    iv_period       IN     VARCHAR2,         -- 期間
    iv_period_id    IN     VARCHAR2,         -- 期間ID
    iv_start_date   IN     VARCHAR2,         -- 開始日付
    iv_end_date     IN     VARCHAR2,         -- 終了日付
    iv_op_code      IN     VARCHAR2,         -- Operators Idenrifier Number
    iv_orgn_code    IN     VARCHAR2,         -- 会社コード
    iv_close_ind    IN     VARCHAR2          -- 処理区分(1:OPEN)
  );
END xxinv590002c;
/
