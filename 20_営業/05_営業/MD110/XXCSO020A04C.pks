CREATE OR REPLACE PACKAGE XXCSO020A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A04C(spec)
 * Description      : SP専決画面からの要求に従って、SP専決画面で入力された情報で発注依頼を
 *                    作成します。
 * MD.050           : MD050_CSO_020_A04_自販機（什器）発注依頼データ連携機能
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-19    1.0   Kazuo.Satomura   新規作成
 *
 *****************************************************************************************/
  --
  --実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                   OUT NOCOPY VARCHAR2                                             -- エラーメッセージ #固定#
    ,retcode                  OUT NOCOPY VARCHAR2                                             -- エラーコード     #固定#
    ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
  );
  --
END XXCSO020A04C;
/
