CREATE OR REPLACE PACKAGE xxpo310002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310002c(spec)
 * Description      : HHT�������IF
 * MD.050           : �������            T_MD050_BPO_310
 * MD.070           : HHT�������IF       T_MD070_BPO_31E
 * Version          : 1.2
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
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_from_date  IN            VARCHAR2,         -- 1.�[����(FROM)
    iv_to_date    IN            VARCHAR2,         -- 2.�[����(TO)
    iv_inv_code   IN            VARCHAR2,         -- 3.�[����R�[�h
    iv_vendor_id  IN            VARCHAR2);        -- 4.�����R�[�h
END xxpo310002c;
/
