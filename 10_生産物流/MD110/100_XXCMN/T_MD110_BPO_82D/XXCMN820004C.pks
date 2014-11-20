CREATE OR REPLACE PACKAGE xxcmn820004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820004c(spec)
 * Description      : 新旧差額計算表作成
 * MD.050/070       : 標準原価マスタDraft1C (T_MD050_BPO_820)
 *                    新旧差額計算表作成    (T_MD070_BPO_82D)
 * Version          : 1.3
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
 *  2008/01/18    1.0   Kazuo Kumamoto   新規作成
 *  2008/05/21    1.1   Masayuki Ikeda   結合テスト障害対応
 *  2008/06/09    1.2   Marushita        レビュー指摘No6対応
 *  2008/06/26    1.3   Marushita        ST不具合No.288,289対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_fiscal_year        IN     VARCHAR2         --   01 : 対象年度
     ,iv_generation         IN     VARCHAR2         --   03 : 世代
     ,iv_prod_div           IN     VARCHAR2         --   04 : 商品区分
     ,iv_output_unit        IN     VARCHAR2         --   05 : 出力単位
     ,iv_crowd_code_01      IN     VARCHAR2         --   06 : 群コード1
     ,iv_crowd_code_02      IN     VARCHAR2         --   07 : 群コード2
     ,iv_crowd_code_03      IN     VARCHAR2         --   08 : 群コード3
     ,iv_crowd_code_04      IN     VARCHAR2         --   09 : 群コード4
     ,iv_crowd_code_05      IN     VARCHAR2         --   10 : 群コード5
    ) ;
END xxcmn820004c;
/
