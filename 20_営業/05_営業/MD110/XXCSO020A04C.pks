CREATE OR REPLACE PACKAGE XXCSO020A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A04C(spec)
 * Description      : SP�ꌈ��ʂ���̗v���ɏ]���āASP�ꌈ��ʂœ��͂��ꂽ���Ŕ����˗���
 *                    �쐬���܂��B
 * MD.050           : MD050_CSO_020_A04_���̋@�i�Y��j�����˗��f�[�^�A�g�@�\
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
 *  2008-12-19    1.0   Kazuo.Satomura   �V�K�쐬
 *
 *****************************************************************************************/
  --
  --���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                   OUT NOCOPY VARCHAR2                                             -- �G���[���b�Z�[�W #�Œ�#
    ,retcode                  OUT NOCOPY VARCHAR2                                             -- �G���[�R�[�h     #�Œ�#
    ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
  );
  --
END XXCSO020A04C;
/
