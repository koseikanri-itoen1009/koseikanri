CREATE OR REPLACE PACKAGE XXINV550005C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550005C(spec)
 * Description      : 棚卸スナップショット作成
 * MD.050/070       : 在庫(帳票)Draft2A (T_MD050_BPO_550)
 *                    棚卸スナップショット作成Draft1A   (T_MD070_BPO_55E)
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
 *  2008/10/22    1.0  Oracle 大橋孝郎  新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2         --   エラーメッセージ
   ,retcode              OUT    VARCHAR2         --   エラーコード
   ,iv_invent_ym         IN     VARCHAR2         --   01. 対象年月	
   ,iv_whse_code1        IN     VARCHAR2         --   02. 倉庫コード１
   ,iv_whse_code2        IN     VARCHAR2         --   03. 倉庫コード２
   ,iv_whse_code3        IN     VARCHAR2         --   04. 倉庫コード３
   ,iv_whse_department1  IN     VARCHAR2         --   05. 倉庫管理部署１
   ,iv_whse_department2  IN     VARCHAR2         --   06. 倉庫管理部署２
   ,iv_whse_department3  IN     VARCHAR2         --   07. 倉庫管理部署３
   ,iv_block1            IN     VARCHAR2         --   08. ブロック１
   ,iv_block2            IN     VARCHAR2         --   09. ブロック２
   ,iv_block3            IN     VARCHAR2         --   10. ブロック３
   ,iv_arti_div_code     IN     VARCHAR2         --   11. 商品区分
   ,iv_item_class_code   IN     VARCHAR2         --   12. 品目区分
  );
END XXINV550005C;
/
