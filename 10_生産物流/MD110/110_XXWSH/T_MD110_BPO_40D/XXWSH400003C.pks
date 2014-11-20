CREATE OR REPLACE PACKAGE xxwsh400003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400003c(package)
 * Description      : �o�׈˗��m��֐�
 * MD.050           : �o�׈˗�               T_MD050_BPO_401
 * MD.070           : �o�׈˗��m��֐�       T_MD070_EDO_BPO_40D
 * Version          : 1.20
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ship_set             �o�׈˗��m��֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   R.Matusita       ����쐬
 *  2008/04/23    1.1   R.Matusita       �����ύX�v��#65
 *  2008/06/03    1.2   M.Uehara         �����ύX�v��#80
 *  2008/06/05    1.3   N.Yoshida        ���[�h�^�C���Ó����`�F�b�N D-2�o�ɓ� > �ғ����ɏC��
 *  2008/06/05    1.4   M.Uehara         �ύڌ����`�F�b�N(�ύڌ����Z�o)�̎��{�������C��
 *  2008/06/05    1.5   N.Yoshida        �o�׉ۃ`�F�b�N�ɂĈ����ݒ�̏C��
 *                                        (���̓p�����[�^�F�Ǌ����_�ˎ󒍃w�b�_�̊Ǌ����_)
 *  2008/06/06    1.6   T.Ishiwata       �o�׉ۃ`�F�b�N�ɂăG���[���b�Z�[�W�̏C��
 *  2008/06/18    1.7   T.Ishiwata       ���߃X�e�[�^�X�`�F�b�N�敪���Q�̏ꍇ�AUpdate����悤�C��
 *                                       �S�̓I�Ƀl�X�g�C��
 *  2008/06/19    1.8   Y.Shindou        �����ύX�v��#143�Ή�
 *  2008/07/08    1.9   N.Fukuda         ST�s��Ή�#405
 *  2008/07/08    1.10  M.Uehara         ST�s��Ή�#424
 *  2008/07/09    1.11  N.Fukuda         ST�s��Ή�#430
 *  2008/07/29    1.12  D.Nihei          ST�s��Ή�#503
 *  2008/07/30    1.13  M.Uehara         ST�s��Ή�#501
 *  2008/08/06    1.14  D.Nihei          ST�s��Ή�#525
 *                                       �J�e�S�����VIEW�ύX
 *  2008/08/11    1.15  M.Hokkanji       �����ۑ�#32�Ή��A�����ύX�v��#173,178�Ή�
 *  2008/09/01    1.16  N.Yoshida        PT�Ή�(�N�[�Ȃ�)
 *  2008/09/24    1.17  M.Hokkanji       TE080_400�w�E66�Ή�
 *  2008/10/15    1.18  Marushita        I_S_387�Ή�
 *  2008/11/18    1.19  M.Hokkanji       �����w�E141�A632�A658�Ή�
 *  2008/11/26    1.20  M.Hokkanji       �{�ԏ�Q133�Ή�
 *
 *****************************************************************************************/
--
  -- �o�׈˗��m��֐�
  PROCEDURE ship_set(
    iv_prod_class            IN VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_head_sales_branch     IN VARCHAR2  DEFAULT NULL, -- �Ǌ����_
    iv_input_sales_branch    IN VARCHAR2  DEFAULT NULL, -- ���͋��_
    in_deliver_to_id         IN NUMBER    DEFAULT NULL, -- �z����ID
    iv_request_no            IN VARCHAR2  DEFAULT NULL, -- �˗�No
    id_schedule_ship_date    IN DATE      DEFAULT NULL, -- �o�ɓ�
    id_schedule_arrival_date IN DATE      DEFAULT NULL, -- ����
    iv_callfrom_flg          IN VARCHAR2,               -- �ďo���t���O
    iv_status_kbn            IN VARCHAR2,               -- ���߃X�e�[�^�X�`�F�b�N�敪
    ov_errbuf                OUT NOCOPY   VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY   VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );    
END xxwsh400003c;
/
