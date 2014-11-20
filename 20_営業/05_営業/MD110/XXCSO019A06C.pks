CREATE OR REPLACE PACKAGE XXCSO019A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A06C(spec)
 * Description      :  �w�肵���c�ƈ��̎w�肵�������܂�1�T�Ԃ̖K��v��(�K���ڋq��)
 *                    ����ʂ�PDF�֏o�͂��܂��B
 *                     �ڋq�͓���̃��[�gNo���Ƃɂ܂Ƃ߁A�T�ԖK��񐔂̑������[�gNo����
 *                    ���ɕ\�����܂��B(���[�gNo��\�����܂��B)
 *                     ���t���̉E�[��1���̌�����\�����܂��B
 * MD.050           : MD050_CSO_019_A06_�K�⑍���Ǘ��\
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
 *  2009-02-16    1.0   Mio.Maruyama     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_standard_date   IN  VARCHAR2                 --   ��N����
   ,iv_employee_number IN  VARCHAR2                 --   �]�ƈ��R�[�h
  );
END XXCSO019A06C;
/
