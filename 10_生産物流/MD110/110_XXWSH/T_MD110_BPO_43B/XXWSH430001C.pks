CREATE OR REPLACE PACKAGE xxwsh430001c
AS

/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh430001c(spec)
 * Description      : 倉替返品情報インターフェイス
 * MD.050           : 倉替返品 T_MD050_BPO_430
 * MD.070           : 倉替返品情報インターフェイス T_MD070_BPO_43B
 * Version          : 1.15
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0   Oracle福田 直樹  初回作成
 *  2008/05/16    1.1   ORACLE石渡賢和   マスタはView参照するよう変更
 *                                       受注明細アドオンの出荷品目ID／依頼品目IDに
 *                                       inventory_item_idをセットするよう変更
 *  2008/05/20    1.2   ORACLE椎名昭圭   内部変更要求#106対応
 *  2008/06/19    1.3   ORACLE石渡賢和   フラグのデフォルト値をセット
 *  2008/08/07    1.4   ORACLE山根一浩   課題#32,課題#67変更#174対応
 *  2008/10/10    1.5   ORACLE平福正明   T_S_474対応
 *  2008/11/25    1.6   ORACLE吉元強樹   本番問合せ#243対応
 *  2008/12/22    1.7   ORACLE椎名昭圭   本番問合せ#743対応
 *  2009/01/06    1.8   Yuko Kawano      本番問合せ#908対応
 *  2009/01/13    1.9   Hitomi Itou      本番問合せ#981対応
 *  2009/01/15    1.10  Masayoshi Uehara 本番問合せ#1019対応
 *  2009/01/22    1.11  ORACLE山本恭久   本番問合せ#1037対応
 *  2009/04/09    1.12  SCS丸下          本番障害#1346
 *  2009/06/30    1.13  Yuki Kazama      本番障害#1335対応
 *  2009/09/29    1.14  H.Itou           本番障害#1465対応
 *  2009/10/20    1.15  H.Itou           本番障害#1569,1591(営業稼動支援)対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- エラーメッセージ #固定#
    retcode             OUT NOCOPY VARCHAR2      -- エラーコード     #固定#
  );
END xxwsh430001c;
/
