/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Table Name  : XXCOS_VD_COLUMN_LINES
 * Description : VD�R�����ʎ�����׃e�[�u��
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/30    1.0   SCS S.Miyakoshi �V�K�쐬
 *  2009/04/13    1.1   SCS N.Maeda     [ST��QNo.T1_0496�Ή�]
 *                                      ��[���̌�����NUMBER(2)��NUMBER�ɏC��
 *  2009/12/07    1.2   SCS K.Kanada    [E_�{�ғ�_00225�Ή�]
 *                                      �sNo.(HHT)�̌�����NUMBER(2)��NUMBER�ɏC��
 *
 ****************************************************************************************/
ALTER TABLE XXCOS.XXCOS_VD_COLUMN_LINES modify 
(
LINE_NO_HHT                     NUMBER        
)
;
