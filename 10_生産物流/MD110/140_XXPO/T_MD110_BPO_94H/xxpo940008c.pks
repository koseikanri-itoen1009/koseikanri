CREATE OR REPLACE PACKAGE xxpo940008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940008c(spec)
 * Description      : ロット引当情報取込処理
 * MD.050           : 取引先オンライン T_MD050_BPO_940
 * MD.070           : ロット引当情報取込処理 T_MD070_BPO_94H
 * Version          : 1.9
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
 *  2008/06/19    1.0  Oracle 吉田夏樹   初回作成
 *  2008/07/22    1.1  Oracle 吉田夏樹   内部課題#32、#66、内部変更#166対応
 *  2008/07/29    1.2  Oracle 吉田夏樹   ST不具合対応(採番なし)
 *  2008/08/22    1.3  Oracle 山根一浩   T_TE080_BPO_940 指摘4,指摘5,指摘17対応
 *  2008/10/08    1.4  Oracle 伊藤ひとみ 統合テスト指摘240対応
 *  2009/02/09    1.5  Oracle 吉田 夏樹  本番#15、1121対応
 *  2009/02/25    1.6  Oracle 吉田 夏樹  本番#1121対応再対応
 *  2009/04/15    1.7  SCS    伊藤ひとみ 本番#1403,1405対応
 *  2009/04/17    1.8  SCS    椎名 昭圭  ロット管理外品はロットIDをNULLとして取得
 *  2009/04/23    1.9  SCS    椎名 昭圭  本番#1420対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT VARCHAR2,              --  エラーメッセージ #固定#
    retcode                   OUT VARCHAR2,              --  エラーコード     #固定#
    iv_data_class             IN  VARCHAR2,              --  データ種別
    iv_deliver_from           IN  VARCHAR2,              --  倉庫
    iv_shipped_date_from      IN  VARCHAR2,              --  出庫日FROM
    iv_shipped_date_to        IN  VARCHAR2,              --  出庫日TO
    iv_instruction_dept       IN  VARCHAR2,              --  指示部署
    iv_security_kbn           IN  VARCHAR2               --  セキュリティ区分
  );
END xxpo940008c;
/
