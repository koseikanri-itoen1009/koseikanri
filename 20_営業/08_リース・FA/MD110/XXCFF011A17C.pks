CREATE OR REPLACE PACKAGE XXCFF011A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF011A17C(spec)
 * Description      : ���[�X��v��J���f�[�^�o��
 * MD.050           : ���[�X��v��J���f�[�^�o�� MD050_CFF_011_A17
 * Version          : 1.7
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
 *  2018/03/27    1.7   SCSK ���H        E_�{�ғ�_14830�iIFRS���[�X���Y�Ή��j
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
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--    iv_lease_company IN    VARCHAR2         -- 4.���[�X��ЃR�[�h
    iv_lease_company IN    VARCHAR2,        -- 4.���[�X��ЃR�[�h
    iv_lease_class   IN    VARCHAR2         -- 5.���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
  );
--
END XXCFF011A17C;
/
