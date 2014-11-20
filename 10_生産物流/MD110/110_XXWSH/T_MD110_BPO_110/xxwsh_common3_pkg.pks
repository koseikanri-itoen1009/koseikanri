CREATE OR REPLACE PACKAGE xxwsh_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common3_pkg(SPEC)
 * Description            : ���ʊ֐�(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  get_wsh_wf_info         P          ���[�N�t���[�������擾
 *  wf_whs_start            P          �o�חp���[�N�t���[�N���֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/06/10   1.0   Oracle �쑺      �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
--
  -- WF�֘A�f�[�^
  TYPE wf_whs_rec IS RECORD(
    wf_class                VARCHAR2(150),
    wf_notification         VARCHAR2(150),
    directory               VARCHAR2(150),
    file_name               VARCHAR2(150),
    file_display_name       VARCHAR2(150),
    wf_name                 VARCHAR2(150),
    wf_owner                VARCHAR2(150),
    user_cd01               VARCHAR2(150),
    user_cd02               VARCHAR2(150),
    user_cd03               VARCHAR2(150),
    user_cd04               VARCHAR2(150),
    user_cd05               VARCHAR2(150),
    user_cd06               VARCHAR2(150),
    user_cd07               VARCHAR2(150),
    user_cd08               VARCHAR2(150),
    user_cd09               VARCHAR2(150),
    user_cd10               VARCHAR2(150)
  );
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- ���[�N�t���[�������擾
  PROCEDURE get_wsh_wf_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    or_wf_whs_rec       OUT NOCOPY wf_whs_rec,        -- �t�@�C�����
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �o�חp ���[�N�t���[�N��
  PROCEDURE wf_whs_start(
    ir_wf_whs_rec IN  wf_whs_rec,               -- ���[�N�t���[�֘A���
    iv_filename   IN  VARCHAR2,                 -- �t�@�C����
    ov_errbuf     OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   );
--
END xxwsh_common3_pkg;
/
