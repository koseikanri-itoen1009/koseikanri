CREATE OR REPLACE PACKAGE XXCOK014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A01C(spec)
 * Description      : �̔����я��E�萔���v�Z��������̔̔��萔���v�Z����
 * MD.050           : �����ʔ̎�̋��v�Z���� MD050_COK_014_A01
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �̔����я��E�萔���v�Z��������̔̔��萔���v�Z����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   K.Ezaki          �V�K�쐬
 *  2009/02/13    1.1   K.Ezaki          ��QCOK_039 �x���������ݒ�ڋq�X�L�b�v
 *  2009/02/17    1.2   K.Ezaki          ��QCOK_040 �t���x���_�[�T�C�g�Œ�C��
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_060 �ꗥ�����v�Z���ʗݐ�
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_061 �ꗥ������z�v�Z
 *  2009/02/25    1.3   K.Ezaki          ��QCOK_062 ��z�������ߗ��E���ߊz���ݒ�
 *  2009/03/25    1.4   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf       OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,retcode      OUT VARCHAR2 -- �G���[�R�[�h
    ,iv_proc_date IN  VARCHAR2 -- �Ɩ����t
    ,iv_proc_type IN  VARCHAR2 -- ���s�敪
  );
END XXCOK014A01C;
/
