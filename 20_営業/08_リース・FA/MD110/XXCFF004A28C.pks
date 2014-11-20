CREATE OR REPLACE PACKAGE XXCFF004A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A28C(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �ă��[�X�v�ۃ_�E�����[�h 004_A28
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_check             p �p�����[�^�`�F�b�N����                  (A-2)
 *  csv_buf                p CSV�ҏW����                             (A-4)
 *  csv_header             p CSV�w�b�_�[�쐬
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   SCS��� �M�K     �V�K�쐬
 *  2009/02/09    1.1   SCS��� �M�K     ���O�o�͍��ڒǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT NOCOPY   VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_date_from   IN  VARCHAR2,            --   1.���[�X�I����FROM
    iv_date_to     IN  VARCHAR2,            --   2.���[�X�I����TO
    iv_class_from  IN  VARCHAR2,            --   3.���[�X���FROM
    iv_class_to    IN  VARCHAR2             --   4.���[�X���TO
  );
END XXCFF004A28C;
/
