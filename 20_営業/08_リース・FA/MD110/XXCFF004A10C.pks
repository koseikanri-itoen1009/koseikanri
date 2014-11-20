CREATE OR REPLACE PACKAGE XXCFF004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A10C(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �ă��[�X�v�ۃA�b�v���[�h CFF_004_A10
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_if_data            p �t�@�C���A�b�v���[�hIF�f�[�^�擾����    (A-2)
 *  devide_item            p �f���~�^�������ڕ���                    (A-3)
 *  insert_work            p �ă��[�X�v�ۃ��[�N�f�[�^�쐬            (A-6)
 *  combination_check      p �g�ݍ��킹�`�F�b�N                      (A-8)
 *  item_validate_check    p ���ڑÓ����`�F�b�N                      (A-9)
 *  re_lease_update        p �������R�[�h���b�N�ƍX�V                (A-11)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   SCS��� �M�K     �V�K�쐬
 *  2009/02/09    1.1   SCS��� �M�K     ���O�o�͍��ڒǉ�
 *  2009/02/25    1.2   SCS��� �M�K     �����񒆂�"��؂���
 *  2009/02/25    1.3   SCS��� �M�K     ���[�U�[���b�Z�[�W�o�͐�ύX
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    in_file_id     IN     NUMBER,           --   1.�t�@�C��ID
    iv_file_format IN     VARCHAR2          --   2.�t�@�C���t�H�[�}�b�g
  );
END XXCFF004A10C;
/
