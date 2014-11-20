CREATE OR REPLACE PACKAGE xxwsh930002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930002c(spec)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・移動インタフェース         T_MD050_BPO_930
 * MD.070           : ＨＨＴ入出庫実績インタフェース   T_MD070_BPO_93B
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/17    1.0  Oracle 岩佐 智治  初回作成
 *  2008/05/19    1.1  Oracle 宮田 隆史  指摘事項Seq262，263，
 *  2008/06/05    1.2  Oracle 宮田 隆史  結合テスト実施に伴う
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,      -- エラーメッセージ #固定#
    retcode                   OUT NOCOPY VARCHAR2,      -- エラーコード     #固定#
    iv_process_object_info    IN  VARCHAR2,             -- 処理対象情報
    iv_report_post            IN  VARCHAR2,             -- 報告部署
    iv_object_warehouse       IN  VARCHAR2              -- 対象倉庫
  );
END xxwsh930002c;
/
