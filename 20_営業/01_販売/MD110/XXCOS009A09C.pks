CREATE OR REPLACE PACKAGE APPS.XXCOS009A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A09C (spec)
 * Description      : �󒍈ꗗ���s��CSV�o��
 * MD.050           : �󒍈ꗗ���s��CSV�o�� MD050_COS_009_A09
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
 *  2012/09/12    1.0   M.Takasaki       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_base_code                    IN     VARCHAR2,         --   ���_�R�[�h
    iv_order_list_date_from         IN     VARCHAR2,         --   �o�͓�(FROM)
    iv_order_list_date_to           IN     VARCHAR2          --   �o�͓�(TO)
  );
END XXCOS009A09C;
/
