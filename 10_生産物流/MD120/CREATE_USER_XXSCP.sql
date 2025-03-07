/****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Script Name     : CREATE_USER_XXSCP
 * Description     : ���Y�v��X�L�[�}�쐬�p
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2024/10/30    1.0   M.Sato           �V�K�쐬
 *  2024/11/26    1.1   M.Sato           XXIDX�ւ̌�����ǉ�
 ****************************************************************************************/
CREATE USER XXSCP IDENTIFIED BY XXSCP DEFAULT TABLESPACE XXDATA TEMPORARY TABLESPACE TEMP QUOTA unlimited on XXDATA QUOTA unlimited on XXIDX;
