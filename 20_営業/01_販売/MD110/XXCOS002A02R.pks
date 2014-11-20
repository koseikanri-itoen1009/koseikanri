CREATE OR REPLACE PACKAGE XXCOS002A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A02R(spec)
 * Description      : �c�ƕ񍐓���
 * MD.050           : �c�ƕ񍐓��� MD050_COS_002_A02
 * Version          : 1.3
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
 *  2008/12/11    1.0   T.Nakabayashi    main�V�K�쐬
 *  2009/02/20    1.1   T.Nakabayashi    get_msg�̃p�b�P�[�W���C��
 *  2009/02/26    1.2   T.Nakabayashi    MD050�ۑ�No153�Ή� �]�ƈ��A�A�T�C�������g�K�p�����f�ǉ�
 *  2009/02/27    1.3   T.Nakabayashi    ���[���[�N�e�[�u���폜���� �R�����g�A�E�g����
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode               OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_delivery_date      IN      VARCHAR2,         --  1.�[�i��
    iv_delivery_base_code IN      VARCHAR2,         --  2.�[�i���_
    iv_dlv_by_code        IN      VARCHAR2          --  3.�c�ƈ��i�[�i�ҁj
  );
END XXCOS002A02R;
/
