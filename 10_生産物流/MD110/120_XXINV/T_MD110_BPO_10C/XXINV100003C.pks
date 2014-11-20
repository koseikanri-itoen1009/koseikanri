CREATE OR REPLACE PACKAGE xxinv100003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100003C(spec)
 * Description      : 販売計画時系列表
 * MD.050/070       : 販売計画・引取計画 (T_MD050_BPO_100)
 *                    販売計画時系列表   (T_MD070_BPO_10C)
 * Version          : 1.8
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
 *  2008/02/15   1.0   Tatsuya Kurata   新規作成
 *  2008/04/23   1.1   Masanobu Kimura  内部変更要求#27
 *  2008/04/28   1.2   Sumie Nakamura   仕入･標準単価ヘッダ(アドオン)抽出条件漏れ対応
 *  2008/04/30   1.3   Yuko Kawano      内部変更要求#62,76
 *  2008/05/28   1.4   Kazuo Kumamoto   規約違反(varchar使用)対応
 *  2008/07/02   1.5   Satoshi Yunba    禁則文字対応
 *  2009/04/16   1.6   吉元 強樹        本番障害対応(No.1410)
 *  2009/05/29   1.7   吉元 強樹        本番障害対応(No.1509)
 *  2009/10/05   1.8   吉元 強樹        本番障害対応(No.1648)
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
      errbuf           OUT    VARCHAR2      --   エラーメッセージ
     ,retcode          OUT    VARCHAR2      --   エラーコード
     ,iv_year          IN     VARCHAR2      --   01.年度
     ,iv_prod_div      IN     VARCHAR2      --   02.商品区分
     ,iv_gen           IN     VARCHAR2      --   03.世代
     ,iv_output_unit   IN     VARCHAR2      --   04.出力単位
     ,iv_output_type   IN     VARCHAR2      --   05.出力種別
     ,iv_base_01       IN     VARCHAR2      --   06.拠点１
     ,iv_base_02       IN     VARCHAR2      --   07.拠点２
     ,iv_base_03       IN     VARCHAR2      --   08.拠点３
     ,iv_base_04       IN     VARCHAR2      --   09.拠点４
     ,iv_base_05       IN     VARCHAR2      --   10.拠点５
     ,iv_base_06       IN     VARCHAR2      --   11.拠点６
     ,iv_base_07       IN     VARCHAR2      --   12.拠点７
     ,iv_base_08       IN     VARCHAR2      --   13.拠点８
     ,iv_base_09       IN     VARCHAR2      --   14.拠点９
     ,iv_base_10       IN     VARCHAR2      --   15.拠点１０
     ,iv_crowd_code_01 IN     VARCHAR2      --   16.群コード１
     ,iv_crowd_code_02 IN     VARCHAR2      --   17.群コード２
     ,iv_crowd_code_03 IN     VARCHAR2      --   18.群コード３
     ,iv_crowd_code_04 IN     VARCHAR2      --   19.群コード４
     ,iv_crowd_code_05 IN     VARCHAR2      --   20.群コード５
     ,iv_crowd_code_06 IN     VARCHAR2      --   21.群コード６
     ,iv_crowd_code_07 IN     VARCHAR2      --   22.群コード７
     ,iv_crowd_code_08 IN     VARCHAR2      --   23.群コード８
     ,iv_crowd_code_09 IN     VARCHAR2      --   24.群コード９
     ,iv_crowd_code_10 IN     VARCHAR2      --   25.群コード１０
    );
END xxinv100003c;
/
