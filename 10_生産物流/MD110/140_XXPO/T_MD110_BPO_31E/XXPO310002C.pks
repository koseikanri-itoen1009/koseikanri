CREATE OR REPLACE PACKAGE xxpo310002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310002c(spec)
 * Description      : HHT�������IF
 * MD.050           : �������            T_MD050_BPO_310
 * MD.070           : HHT�������IF       T_MD070_BPO_31E
 * Version          : 1.6
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
 *  2008/04/08    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/21    1.1   Oracle �R�� ��_ �ύX�v��No43�Ή�
 *  2008/05/23    1.2   Oracle ���� �Ǖ� �����e�X�g�s��i�V�i���I4-1�j
 *  2008/07/14    1.3   Oracle �Ŗ� ���\ �d�l�s����Q#I_S_001.4,#I_S_192.1.2,#T_S_435�Ή�
 *  2008/09/01    1.4   Oracle �R�� ��_ T_TE080_BPO_310 �w�E9�Ή�
 *  2008/09/17    1.5   Oracle �勴 �F�Y �w�E204�Ή�
 *  2009/01/26    1.6   Oracle �Ŗ� ���\ �{��#1046�Ή�
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_from_date  IN            VARCHAR2,         -- 1.�[����(FROM)
    iv_to_date    IN            VARCHAR2,         -- 2.�[����(TO)
-- 2008/07/14 1.3 UPDATE Start
--    iv_inv_code   IN            VARCHAR2,         -- 3.�[����R�[�h
--    iv_vendor_id  IN            VARCHAR2)         -- 4.�����R�[�h
    iv_inv_code_01 IN           VARCHAR2,         -- 03.�[����R�[�h01
    iv_inv_code_02 IN           VARCHAR2,         -- 04.�[����R�[�h02
    iv_inv_code_03 IN           VARCHAR2,         -- 05.�[����R�[�h03
    iv_inv_code_04 IN           VARCHAR2,         -- 06.�[����R�[�h04
    iv_inv_code_05 IN           VARCHAR2,         -- 07.�[����R�[�h05
    iv_inv_code_06 IN           VARCHAR2,         -- 08.�[����R�[�h06
    iv_inv_code_07 IN           VARCHAR2,         -- 09.�[����R�[�h07
    iv_inv_code_08 IN           VARCHAR2,         -- 10.�[����R�[�h08
    iv_inv_code_09 IN           VARCHAR2,         -- 11.�[����R�[�h09
    iv_inv_code_10 IN           VARCHAR2,         -- 12.�[����R�[�h10
    iv_vendor_id   IN           VARCHAR2);        -- 13.�����R�[�h
-- 2008/07/14 1.3 UPDATE End
END xxpo310002c;
/
