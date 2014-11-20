CREATE OR REPLACE PACKAGE APPS.XXCSO019A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A07C(spec)
 * Description      : �w�肵���c�ƈ��̎w�肵�����̂P���Ԃ��Ƃ̖K�����(�K���)��\�����܂��B
 *                    �P�T�ԑO�̖K����т𓯗l�ɕ\�����Ĕ�r�̑ΏۂƂ��܂��B
 * MD.050           : MD050_CSO_019_A07_�c�ƈ��ʖK����ѕ\
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
 *  2009-01-30    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_visit_date      IN  VARCHAR2                 --   �K���
   ,iv_employee_number IN  VARCHAR2                 --   �]�ƈ��R�[�h
  );
END XXCSO019A07C;
/
