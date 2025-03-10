CREATE OR REPLACE PACKAGE XXCMM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A01C(body)
 * Description      : 社員データ取込処理
 * MD.050           : 社員データ取込処理MD050_CMM_002_A01
 * Version          : 3.8
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
 *  2009/01/09    1.0   SCS 工藤 真純    初回作成
 *  2009/03/09    1.1   SCS 竹下 昭範    正常終了時だけ、CSVファイルを削除するように変更
 *  2009/04/03    1.2   SCS 吉川 博章    追加従業員情報詳細のコンテキスト設定を追加
 *  2009/04/16    1.3   SCS 吉川 博章    障害No.483 対応
 *                                       submain の処理を大幅修正
 *  2009/05/21    1.4   SCS 吉川 博章    障害No.T1_0966 対応
 *  2009/05/29                           障害No.T1_0966 対応(再雇用時の対応漏れ)
 *  2009/06/02    1.5   SCS 西村 昇      障害No.T1_1277 対応(APIエラーメッセージ)
 *                                       障害No.T1_1278 対応(SQLパフォーマンス)
 *                                       旧コード類のチェック追加
 *  2009/06/23    1.6   SCS 吉川 博章    障害No.T1_1389 対応
 *                                       (アサイメント管理者の抽出方法・場所を変更)
 *  2009/06/25    1.7   SCS 吉川 博章    障害No.0000161 対応
 *  2009/07/06    1.8   SCS 伊藤 和之    障害No.0000412 対応(PT対応)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2          --   エラーコード     #固定#
  );
  --
END XXCMM002A01C;
/
