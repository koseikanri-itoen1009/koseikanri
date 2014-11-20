create or replace
PACKAGE XXCFF016A36C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A36C(spec)
 * Description      : ���[�X�_�񖾍׃����e�i���X
 * MD.050           : MD050_CFF_016_A36_���[�X�_�񖾍׃����e�i���X.
 * Version          : 1.1
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
 *  2012/10/12    1.0   SCSK �ÎR         �V�K�쐬
 *  2013/07/11    1.1   SCSK ����         E_�{�ғ�_10871 ����őΉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT   VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT   VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_object_code            IN    VARCHAR2,   --   1.�����R�[�h
    iv_contract_number        IN    VARCHAR2,   --   2.�_��ԍ�
    iv_update_reason          IN    VARCHAR2,   --   3.�X�V���R
    iv_first_charge           IN    VARCHAR2,   --   4.���񃊁[�X��
    iv_second_charge          IN    VARCHAR2,   --   5.2��ڈȍ~�̃��[�X��
    iv_first_tax_charge       IN    VARCHAR2,   --   6.��������
    iv_second_tax_charge      IN    VARCHAR2,   --   7.2��ڈȍ~�̏����
-- Mod 2013/07/11 Ver.1.1 Start
--    iv_estimated_cash_price   IN    VARCHAR2    --   8.���ό����w�����z
    iv_estimated_cash_price   IN    VARCHAR2,   --   8.���ό����w�����z
    iv_tax_code               IN    VARCHAR2    --   9.�ŋ��R�[�h
-- Mod 2013/07/11 Ver.1.1 End
  );
END XXCFF016A36C;
/
