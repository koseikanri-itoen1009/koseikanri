CREATE OR REPLACE PACKAGE XXCFF011A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF011A17C(spec)
 * Description      : ���[�X��v��J���f�[�^�o��
 * MD.050           : ���[�X��v��J���f�[�^�o�� MD050_CFF_011_A17
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
 *  2008/12/01    1.0   SCS�R��          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_period_name   IN    VARCHAR2,        -- 1.��v���Ԗ�
    iv_lease_kind    IN    VARCHAR2,        -- 2.���[�X���
    iv_book_class    IN    VARCHAR2,        -- 3.���Y�䒠�敪
    iv_lease_company IN    VARCHAR2         -- 4.���[�X��ЃR�[�h
  );
--
END XXCFF011A17C;
/
