CREATE OR REPLACE PACKAGE xxwip720001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip720001c(spec)
 * Description      : �z�������A�h�I���}�X�^�捞����
 * MD.050           : �^���v�Z�i�}�X�^�j T_MD050_BPO_720
 * MD.070           : �z�������A�h�I���}�X�^�捞����(72D) T_MD070_BPO_72D
 * Version          : 1.3
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
 *  2007/12/12    1.0   H.Itou           main �V�K�쐬
 *  2008/09/02    1.1   A.Shiina         �����ύX�v��#204�Ή�
 *  2009/04/03    1.2   A.Shiina         �{��#432�Ή�
 *  2016/06/22    1.3   K.Kiriu          E_�{�ғ�_13659�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
-- v1.3 MOD START
--    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_prod_div   IN     VARCHAR2          --   ���i�敪
-- v1.3 MOD END
  );
END xxwip720001c;
/
