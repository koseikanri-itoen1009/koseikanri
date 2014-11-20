CREATE OR REPLACE PACKAGE APPS.xxcso_task_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_TASK_COMMON_PKG(SPEC)
 * Description      : ���ʊ֐�(XXCSO�^�X�N�j
 * MD.050/070       :
 * Version          : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  create_task               P    -     �K��^�X�N�o�^�֐�
 *  update_task               P    -     �K��^�X�N�X�V�֐�
 *  delete_task               P    -     �K��^�X�N�폜�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Cho            �V�K�쐬
 *  2008/12/16    1.0   T.maruyama       �K��^�X�N�폜�֐�
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *  2009-07-16    1.2   Kazuo.Satomura   0000070�Ή�
 *****************************************************************************************/
--
  -- �K��^�X�N�o�^�֐�
  PROCEDURE create_task(
    in_resource_id           IN  NUMBER,                 -- �c�ƈ��R�[�h�̃��\�[�XID
    in_party_id              IN  NUMBER,                 -- �ڋq�̃p�[�e�BID
    iv_party_name            IN  VARCHAR2,               -- �ڋq�̃p�[�e�B����
    id_visit_date            IN  DATE,                   -- ���яI�����i�K������j
    iv_description           IN  VARCHAR2 DEFAULT NULL,  -- �ڍד��e
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    it_task_status_id        IN  jtf_task_statuses_b.task_status_id%TYPE DEFAULT NULL,-- �^�X�N�X�e�[�^�X�h�c
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    iv_attribute1            IN  VARCHAR2 DEFAULT NULL,  -- DFF1
    iv_attribute2            IN  VARCHAR2 DEFAULT NULL,  -- DFF2
    iv_attribute3            IN  VARCHAR2 DEFAULT NULL,  -- DFF3
    iv_attribute4            IN  VARCHAR2 DEFAULT NULL,  -- DFF4
    iv_attribute5            IN  VARCHAR2 DEFAULT NULL,  -- DFF5
    iv_attribute6            IN  VARCHAR2 DEFAULT NULL,  -- DFF6
    iv_attribute7            IN  VARCHAR2 DEFAULT NULL,  -- DFF7
    iv_attribute8            IN  VARCHAR2 DEFAULT NULL,  -- DFF8
    iv_attribute9            IN  VARCHAR2 DEFAULT NULL,  -- DFF9
    iv_attribute10           IN  VARCHAR2 DEFAULT NULL,  -- DFF10
    iv_attribute11           IN  VARCHAR2 DEFAULT NULL,  -- DFF11
    iv_attribute12           IN  VARCHAR2 DEFAULT NULL,  -- DFF12
    iv_attribute13           IN  VARCHAR2 DEFAULT NULL,  -- DFF13
    iv_attribute14           IN  VARCHAR2 DEFAULT NULL,  -- DFF14
    on_task_id               OUT NUMBER,                 -- �^�X�NID
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ����:0�A�x��:1�A�ُ�:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  -- �K��^�X�N�X�V�֐�
  PROCEDURE update_task(
    in_task_id               IN  NUMBER,                 -- �^�X�NID
    in_resource_id           IN  NUMBER,                 -- �c�ƈ��R�[�h�̃��\�[�XID
    in_party_id              IN  NUMBER,                 -- �ڋq�̃p�[�e�BID
    iv_party_name            IN  VARCHAR2,               -- �ڋq�̃p�[�e�B����
    id_visit_date            IN  DATE,                   -- ���яI�����i�K������j
    iv_description           IN  VARCHAR2 DEFAULT NULL,  -- �ڍד��e
    in_obj_ver_num           IN  NUMBER,                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    it_task_status_id        IN  jtf_task_statuses_b.task_status_id%TYPE DEFAULT NULL,-- �^�X�N�X�e�[�^�X�h�c
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
    iv_attribute1            IN  VARCHAR2 DEFAULT NULL,  -- DFF1
    iv_attribute2            IN  VARCHAR2 DEFAULT NULL,  -- DFF2
    iv_attribute3            IN  VARCHAR2 DEFAULT NULL,  -- DFF3
    iv_attribute4            IN  VARCHAR2 DEFAULT NULL,  -- DFF4
    iv_attribute5            IN  VARCHAR2 DEFAULT NULL,  -- DFF5
    iv_attribute6            IN  VARCHAR2 DEFAULT NULL,  -- DFF6
    iv_attribute7            IN  VARCHAR2 DEFAULT NULL,  -- DFF7
    iv_attribute8            IN  VARCHAR2 DEFAULT NULL,  -- DFF8
    iv_attribute9            IN  VARCHAR2 DEFAULT NULL,  -- DFF9
    iv_attribute10           IN  VARCHAR2 DEFAULT NULL,  -- DFF10
    iv_attribute11           IN  VARCHAR2 DEFAULT NULL,  -- DFF11
    iv_attribute12           IN  VARCHAR2 DEFAULT NULL,  -- DFF12
    iv_attribute13           IN  VARCHAR2 DEFAULT NULL,  -- DFF13
    iv_attribute14           IN  VARCHAR2 DEFAULT NULL,  -- DFF14
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ����:0�A�x��:1�A�ُ�:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  -- �K��^�X�N�폜�֐�
  PROCEDURE delete_task(
    in_task_id               IN  NUMBER,                 -- �^�X�NID
    in_obj_ver_num           IN  NUMBER,                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ����:0�A�x��:1�A�ُ�:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
END XXCSO_TASK_COMMON_PKG;
/
