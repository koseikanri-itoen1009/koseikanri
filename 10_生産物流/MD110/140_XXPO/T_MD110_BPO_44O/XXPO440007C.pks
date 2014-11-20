CREATE OR REPLACE PACKAGE xxpo440007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440007c(spec)
 * Description      : �x�����i�ύX����
 * MD.050           : �L���x��            T_MD050_BPO_440
 * MD.070           : �x�����i�ύX����    T_MD070_BPO_44O
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/15    1.0   Oracle �R�� ��_ ����쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_dept_code   IN            VARCHAR2,         -- 1.�S�������R�[�h
    iv_from_date   IN            VARCHAR2,         -- 2.���ɓ�(FROM)
    iv_to_date     IN            VARCHAR2,         -- 3.���ɓ�(TO)
    iv_prod_class  IN            VARCHAR2,         -- 4.���i�敪
    iv_item_class  IN            VARCHAR2,         -- 5.�i�ڋ敪
    iv_vendor_code IN            VARCHAR2,         -- 6.�����R�[�h
    iv_item_code   IN            VARCHAR2,         -- 7.�i�ڃR�[�h
    iv_request_no  IN            VARCHAR2);        -- 8.�˗�No
END xxpo440007c;
/
