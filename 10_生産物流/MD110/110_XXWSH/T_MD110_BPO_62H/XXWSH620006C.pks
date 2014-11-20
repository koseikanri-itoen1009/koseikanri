CREATE OR REPLACE PACKAGE xxwsh620006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620006c(spec)
 * Description      : 出庫調整表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 出庫調整表 T_MD070_BPO_62H
 * Version          : 1.0
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
 *  2008/04/18    1.0   Nozomi Kashiwagi 新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1)
                          );
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2      -- エラーメッセージ
    ,retcode                OUT    VARCHAR2      -- エラーコード
    ,iv_concurrent_id       IN     VARCHAR2      -- 01:コンカレントID
    ,iv_biz_type            IN     VARCHAR2      -- 02:業務種別
    ,iv_block1              IN     VARCHAR2      -- 03:ブロック1
    ,iv_block2              IN     VARCHAR2      -- 04:ブロック2
    ,iv_block3              IN     VARCHAR2      -- 05:ブロック3
    ,iv_shiped_code         IN     VARCHAR2      -- 06:出庫元
    ,iv_shiped_date_from    IN     VARCHAR2      -- 07:出庫日From  ※必須
    ,iv_shiped_date_to      IN     VARCHAR2      -- 08:出庫日To
    ,iv_shiped_form         IN     VARCHAR2      -- 09:出庫形態
    ,iv_confirm_request     IN     VARCHAR2      -- 10:確認依頼
    ,iv_warning             IN     VARCHAR2      -- 11:警告
  );
END xxwsh620006c;
/
