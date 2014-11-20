CREATE OR REPLACE PACKAGE APPS.XXCSO020A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A02C(spec)
 * Description      : �t���x���_�[�p�r�o�ꌈ�E�o�^��ʂ���n�����������ƂɎw�肳�ꂽ
 *                    �񑗐�Ƀ��[�N�t���[�ʒm�𑗕t���܂��B
 * MD.050           : MD050_CSO_020_A02_�ʒm�E���F���[�N�t���[�@�\
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-22    1.0   Noriyuki.Yabuki  �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
  --
  --���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     iv_notify_type           IN         VARCHAR2    -- �ʒm�敪
   , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
   , iv_send_employee_number  IN         VARCHAR2    -- �񑗌��]�ƈ��ԍ�
   , iv_dest_employee_number  IN         VARCHAR2    -- �񑗐�]�ƈ��ԍ�
   , errbuf                   OUT NOCOPY VARCHAR2    -- �G���[���b�Z�[�W #�Œ�#
   , retcode                  OUT NOCOPY VARCHAR2    -- �G���[�R�[�h     #�Œ�#
  );
  --
END XXCSO020A02C;
/
