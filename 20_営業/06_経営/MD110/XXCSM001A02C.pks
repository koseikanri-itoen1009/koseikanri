CREATE OR REPLACE PACKAGE XXCSM001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A02C(spec)
 * Description      : EBS(ファイルアップロードIF)に取込まれた年間計画データを
 *                  : 販売計画テーブル(アドオン)に取込みます。
 * MD.050           : 予算データチェック取込(年間計画)
 * Version          :  Draft2.0E.doc
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
 *  2008/11/18    1.0   M.Ohtsuki         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    NOCOPY VARCHAR2                                                            -- エラーメッセージ
   ,retcode       OUT    NOCOPY VARCHAR2                                                            -- エラーコード
   ,iv_file_id    IN     VARCHAR2                                                                   -- ファイルID
   ,iv_format     IN     VARCHAR2                                                                   -- フォーマット
  );
END XXCSM001A02C;
/
