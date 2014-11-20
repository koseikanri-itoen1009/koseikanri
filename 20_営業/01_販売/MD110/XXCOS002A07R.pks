CREATE OR REPLACE PACKAGE APPS.XXCOS002A07R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A07R(spec)
 * Description      : �x���_�[����E�����ƍ��\
 * MD.050           : MD050_COS_002_A07_�x���_�[����E�����ƍ��\
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
 *  2012/10/15    1.0   K.Nakamura       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf              OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    , retcode             OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    , iv_manager_flag     IN  VARCHAR2 -- �Ǘ��҃t���O
    , iv_yymm_from        IN  VARCHAR2 -- �N���iFrom�j
    , iv_yymm_to          IN  VARCHAR2 -- �N���iTo�j
    , iv_base_code        IN  VARCHAR2 -- ���_�R�[�h
    , iv_dlv_by_code      IN  VARCHAR2 -- �c�ƈ��R�[�h
    , iv_cust_code        IN  VARCHAR2 -- �ڋq�R�[�h
    , iv_overs_and_shorts IN  VARCHAR2 -- �����ߕs��
    , iv_counter_error    IN  VARCHAR2 -- �J�E���^�덷
  );
END XXCOS002A07R;
/
