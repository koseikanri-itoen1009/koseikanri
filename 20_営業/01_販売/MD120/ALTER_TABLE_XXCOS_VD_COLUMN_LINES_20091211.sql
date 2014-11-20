/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Table Name  : XXCOS_VD_COLUMN_LINES
 * Description : VDコラム別取引明細テーブル
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/30    1.0   SCS S.Miyakoshi 新規作成
 *  2009/04/13    1.1   SCS N.Maeda     [ST障害No.T1_0496対応]
 *                                      補充数の桁数をNUMBER(2)⇒NUMBERに修正
 *  2009/12/07    1.2   SCS K.Kanada    [E_本稼動_00225対応]
 *                                      行No.(HHT)の桁数をNUMBER(2)⇒NUMBERに修正
 *
 ****************************************************************************************/
ALTER TABLE XXCOS.XXCOS_VD_COLUMN_LINES modify 
(
LINE_NO_HHT                     NUMBER        
)
;
