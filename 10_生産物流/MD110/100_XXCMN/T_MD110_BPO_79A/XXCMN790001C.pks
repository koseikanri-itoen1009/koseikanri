CREATE OR REPLACE PACKAGE xxcmn790001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790001c(spec)
 * Description      : 原料費原価計算処理
 * MD.050           : ロット別実際原価計算 T_MD050_BPO_790
 * MD.070           : 原料費原価計算処理 T_MD070_BPO_79A
 * Version          : 1.7
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
 *  2008/01/31    1.0   Y.Kanami         main新規作成
 *  2008/10/27    1.1   H.Itou           T_S_500,T_S_631対応
 *  2008/11/28    1.2   H.Marushita      本番245対応
 *  2008/12/02    1.3   H.Marushita      数量合計0の取引別ロット原価作成
 *  2008/12/06    1.4   H.Marushita      削除処理条件修正
 *  2008/12/18    1.5   N.Yoshida        本番#777対応
 *  2009/03/30    1.6   H.Iida           本番障害#1346対応
 *  2009/09/24    1.7   H.Marushita      本番障害#1638対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf  OUT NOCOPY  VARCHAR2,   --   エラーメッセージ #固定#
    retcode OUT NOCOPY  VARCHAR2    --   エラーコード     #固定#
  );
END xxcmn790001c;
/
