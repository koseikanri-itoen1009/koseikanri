CREATE OR REPLACE PACKAGE xxpo940002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940002c(spec)
 * Description      : 出来高実績取込処理
 * MD.050           : 取引先オンライン T_MD050_BPO_940
 * MD.070           : 出来高実績取込処理 T_MD070_BPO_94B
 * Version          : 1.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/06/06    1.0   Oracle 伊藤ひとみ   初回作成
 *  2008/07/08    1.1   Oracle 山根一浩     I_S_192対応
 *  2008/07/22    1.2   Oracle 伊藤ひとみ   内部課題#32対応
 *  2008/08/18    1.3   Oracle 伊藤ひとみ   T_S_595 品目情報VIEW2を製造日基準で抽出する
 *  2008/12/02    1.4   SCS    伊藤ひとみ   本番障害#171
 *  2008/12/24    1.5   SCS    山本 恭久    本番障害#743
 *  2008/12/26    1.6   SCS    伊藤 ひとみ  本番障害#809
 *  2009/02/09    1.7   SCS    吉田 夏樹    本番#15、#1178対応
 *  2009/03/13    1.8   SCS    伊藤 ひとみ  本番#32対応
 *  2009/03/24    1.9   SCS    飯田 甫      本番障害#1317対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_data_class             IN  VARCHAR2,   --   データ種別
    iv_vendor_code            IN  VARCHAR2,   --   取引先
    iv_factory_code           IN  VARCHAR2,   --   工場
    iv_manufactured_date_from IN  VARCHAR2,   --   生産日FROM
    iv_manufactured_date_to   IN  VARCHAR2,   --   生産日TO
    iv_security_kbn           IN  VARCHAR2    --   セキュリティ区分
  );
END xxpo940002c;
/
