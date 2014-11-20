CREATE OR REPLACE PACKAGE xxpo940006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940006C(spec)
 * Description      : 支給依頼取込処理
 * MD.050           : 取引先オンライン T_MD050_BPO_940
 * MD.070           : 支給依頼取込処理 T_MD070_BPO_94F
 * Version          : 1.11
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/06/13    1.0   Oracle 椎名        初回作成
 *  2008/06/30    1.1   Oracle 椎名        運賃区分･指示部署･付帯コード、初期値設定
 *                                         登録ステータス変更
 *  2008/07/08    1.2   Oracle 山根一浩    I_S_192対応
 *  2008/07/17    1.3   Oracle 椎名        MD050指摘事項#13対応
 *  2008/07/24    1.4   Oracle 椎名        内部課題#32,内部変更#166･#173対応
 *  2008/07/29    1.5   Oracle 椎名        ST不具合対応
 *  2008/07/30    1.6   Oracle 椎名        ST不具合対応
 *  2008/08/28    1.7   Oracle 山根一浩    T_TE080_BPO_940 指摘16対応
 *  2008/10/08    1.8   Oracle 伊藤ひとみ  統合テスト指摘240対応
 *  2008/10/31    1.9   Oracle 伊藤ひとみ  統合テスト指摘528対応
 *  2009/02/09    1.10  Oracle 吉田 夏樹   本番#15対応
 *  2009/06/08    1.11  SCS    伊藤ひとみ  本番#1526対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2,      --   エラーメッセージ #固定#
    retcode           OUT NOCOPY VARCHAR2,      --   エラーコード     #固定#
    iv_data_class     IN         VARCHAR2,      -- 1.データ種別
    iv_trans_type     IN         VARCHAR2,      -- 2.発生区分
    iv_req_dept       IN         VARCHAR2,      -- 3.依頼部署
    iv_vendor         IN         VARCHAR2,      -- 4.取引先
    iv_ship_to        IN         VARCHAR2,      -- 5.配送先
    iv_arvl_time_from IN         VARCHAR2,      -- 6.入庫日FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.入庫日TO
    iv_security_class IN         VARCHAR2       -- 8.セキュリティ区分
  );
END xxpo940006c;
/
