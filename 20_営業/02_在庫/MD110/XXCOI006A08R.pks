CREATE OR REPLACE PACKAGE XXCOI006A08R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A08R(spec)
 * Description      : �v���̔��s��ʂ���A�i�ږ��̖��ׂ���ђI�����ʂ𒠕[�ɏo�͂��܂��B
 *                    ���[�ɏo�͂����I�����ʃf�[�^�ɂ͏����σt���O"Y"��ݒ肵�܂��B
 * MD.050           : �I���`�F�b�N���X�g    MD050_COI_006_A08
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
 *  2008/11/10    1.0   Sai.u            main�V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       [��QT1_0877] �ŏI�s�Ƀo�b�N�X���b�V����ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_inventory_kbn   IN  VARCHAR2,     -- �I���敪
    iv_practice_date   IN  VARCHAR2,     -- �N����
    iv_practice_month  IN  VARCHAR2,     -- �N��
    iv_base_code       IN  VARCHAR2,     -- ���_
    iv_inventory_place IN  VARCHAR2,     -- �I���ꏊ
    iv_output_kbn      IN  VARCHAR2      -- �o�͋敪
  );
END XXCOI006A08R;
/
