CREATE OR REPLACE PACKAGE xxpo360002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360002c(spec)
 * Description      : 出庫予定表
 * MD.050/070       : 有償支給帳票Issue1.0 (T_MD050_BPO_360)
 *                    有償支給帳票Issue1.0 (T_MD070_BPO_36C)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/03/12    1.0   hirofumi yamazato  新規作成
 *
 ****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   ####################
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
  PROCEDURE main (
      errbuf          OUT    VARCHAR2         --   エラーメッセージ
     ,retcode         OUT    VARCHAR2         --   エラーコード
     ,iv_vend_code    IN     VARCHAR2         --   01 : 出庫元
     ,iv_dlv_f        IN     VARCHAR2         --   02 : 納入日FROM
     ,iv_dlv_t        IN     VARCHAR2         --   03 : 納入日TO
     ,iv_goods_class  IN     VARCHAR2         --   04 : 商品区分
     ,iv_item_class   IN     VARCHAR2         --   05 : 品目区分
     ,iv_item_code    IN     VARCHAR2         --   06 : 品目
     ,iv_dept_code    IN     VARCHAR2         --   07 : 入庫倉庫
     ,iv_seqrt_class  IN     VARCHAR2         --   08 : セキュリティ区分
    ) ;
END xxpo360002c;
/
