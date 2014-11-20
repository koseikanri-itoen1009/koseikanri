CREATE OR REPLACE PACKAGE xxwsh930006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930006C(spec)
 * Description      : インタフェースデータ削除処理
 * MD.050           : 生産物流共通                  T_MD050_BPO_935
 * MD.070           : インタフェースデータ削除処理  T_MD070_BPO_93F
 * Version          : 1.1
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
 *  2008/04/22    1.0   Oracle 山根 一浩 初回作成
 *  2008/12/12    1.1   Oracle 福田 直樹 本番障害#702対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,        --   エラーメッセージ #固定#
    retcode             OUT NOCOPY VARCHAR2,        --   エラーコード     #固定#
    iv_location_code IN            VARCHAR2,        -- 1.報告部署         #必須#
    iv_eos_data_type IN            VARCHAR2,        -- 2.EOSデータ種別    #必須#
    iv_order_ref     IN            VARCHAR2         -- 3.依頼№/移動№    #任意#
  );
END xxwsh930006c;
/
