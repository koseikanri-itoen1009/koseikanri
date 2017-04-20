CREATE OR REPLACE PACKAGE BODY APPS.xxcso_task_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_TASK_COMMON_PKG(BODY)
 * Description      : ���ʊ֐�(XXCSO�^�X�N�j
 * MD.050/070       :
 * Version          : 1.5
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
 *  2008/12/25    1.0   M.maruyama       API�N��������OUT�p�����[�^'gx_return_status'�̐���I��
 *                                       ����l��'S'����'fnd_api.g_ret_sts_success'�֕ύX
 *  2009/05/01    1.1   Tomoko.Mori      T1_0897�Ή�
 *  2009/05/22    1.2   K.Satomura       T1_1080�Ή�
 *  2009/07/16    1.3   K.Satomura       0000070�Ή�
 *  2009/10/23    1.4   Daisuke.Abe      ��Q�Ή�(E_T4_00056)
 *  2017/04/12    1.5   Y.Shoji          E_�{�ғ�_14025�Ή�
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_task_common_pkg';   -- �p�b�P�[�W��
  cv_app_name         CONSTANT VARCHAR2(5)   := 'XXCSO';                   -- �A�v���P�[�V�����Z�k��
  cv_msg_part         CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)   := '.';

  --*** ���������ʗ�O ***
  g_process_expt      EXCEPTION;
  --*** ���ʊ֐���O ***
  g_api_expt          EXCEPTION;
--
   /**********************************************************************************
   * Function Name    : create_task
   * Description      : �K��^�X�N�o�^����
   ***********************************************************************************/
  PROCEDURE create_task(
    in_resource_id           IN  NUMBER,                 -- �c�ƈ��R�[�h�̃��\�[�XID
    in_party_id              IN  NUMBER,                 -- �ڋq�̃p�[�e�BID
    iv_party_name            IN  VARCHAR2,               -- �ڋq�̃p�[�e�B����
-- 2017/04/12 Ver.1.5 Y.Shoji ADD Start
    id_input_date            IN  DATE     DEFAULT NULL,  -- �f�[�^���͓���
-- 2017/04/12 Ver.1.5 Y.Shoji ADD End
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
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'create_task';
--
    -- �v���t�@�C���E�I�v�V����
    cv_prfnm_visit_task_name         CONSTANT VARCHAR2(100) := 'XXCSO1_VISIT_TASK_NAME'; -- �^�X�N����
    cv_prfnm_task_type_name          CONSTANT VARCHAR2(100) := 'XXCSO1_HHT_TASK_TYPE'; -- �^�X�N�^�C�v����
    cv_prfnm_task_status_closed_id   CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_CLOSED_ID'; -- �^�X�N�X�e�[�^�X
--
    -- ���b�Z�[�W�R�[�h
    cv_tkn_number_01           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- �v���t�@�C���擾�G���[
    cv_tkn_number_02           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00155';  -- ���o�G���[
--
    -- �g�[�N���R�[�h
    cv_tkn_err_msg             CONSTANT VARCHAR2(20) := 'ERR_MSG';
    cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
    cv_tkn_task_nm             CONSTANT VARCHAR2(20) := 'TASK_NAME';
--
    cv_task_type_id_nm         CONSTANT VARCHAR2(100) := '�^�X�N�^�C�vID';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_task_name               VARCHAR2(100); -- �^�X�N����
    lv_task_type_name          VARCHAR2(100); -- �^�X�N�^�C�v����
    ln_task_type_id            NUMBER;        -- �^�X�N�^�C�vID
    lv_task_status_id          VARCHAR2(100); -- �^�X�N�X�e�[�^�XID
    ln_task_status_id          NUMBER;        -- �^�X�N�X�e�[�^�XID
--
    -- API�߂�l
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- *** �^�X�N���̎擾 ***
    FND_PROFILE.GET(
                  cv_prfnm_visit_task_name
                 ,lv_task_name
    ); 
    -- �擾�����l���Ȃ��ꍇ
    IF (lv_task_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_prfnm_visit_task_name     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
--
    -- *** �^�X�N�^�C�vID�擾 ***
    -- �^�X�N�^�C�v���̎擾
    FND_PROFILE.GET(
                  cv_prfnm_task_type_name
                 ,lv_task_type_name
    ); 
    -- �擾�����l���Ȃ��ꍇ
    IF (lv_task_type_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_prfnm_task_type_name      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
    -- �^�X�N�^�C�vID�擾
    BEGIN
--
      SELECT jttv.task_type_id
      INTO ln_task_type_id
      FROM jtf_task_types_vl jttv
      WHERE jttv.name = lv_task_type_name
        AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(jttv.start_date_active, SYSDATE))
        AND TRUNC(NVL(jttv.end_date_active, SYSDATE));
    EXCEPTION
      WHEN OTHERS THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_task_type_id_nm      -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h1
                      ,iv_token_value2 => SQLERRM      -- �g�[�N���l1
                    );
       lv_errbuf := lv_errmsg;
       RAISE g_process_expt;
    END;
--
    -- *** �^�X�N�X�e�[�^�XID ***
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    IF (it_task_status_id IS NULL) THEN
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
      FND_PROFILE.GET(
                    cv_prfnm_task_status_closed_id
                   ,lv_task_status_id
      ); 
      -- �擾���s�����ꍇ
      IF (lv_task_status_id IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_prof_nm                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_prfnm_task_status_closed_id -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE g_process_expt;
      ELSE
        ln_task_status_id := TO_NUMBER(lv_task_status_id);
      END IF;
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    ELSE
      ln_task_status_id := it_task_status_id;
      --
    END IF;
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
    ------------------
    ---- API �N�� ----
    ------------------
    JTF_TASKS_PUB.CREATE_TASK(
       p_api_version             => 1.0                      -- �o�[�W�����i���o�[
      ,p_task_name               => lv_task_name             -- �^�X�N����
      ,p_task_type_id            => ln_task_type_id          -- �^�X�N�^�C�vID
      ,p_description             => iv_description           -- �E�v
      ,p_task_status_id          => ln_task_status_id        -- �^�X�N�X�e�[�^�X
      ,p_owner_type_code         => 'RS_EMPLOYEE'            -- �^�X�N���L�҃^�C�v�R�[�h
      ,p_owner_id                => in_resource_id           -- �^�X�N���L��ID
      /* 2009.05.22 K.Satomura T1_1080�Ή� START */
      ,p_customer_id             => in_party_id              -- �p�[�e�B�[ID
      /* 2009.05.22 K.Satomura T1_1080�Ή� END */
-- 2017/04/10 Ver.1.5 Y.Shoji ADD Start
      ,p_planned_end_date        => id_input_date            -- �f�[�^���͓���
-- 2017/04/10 Ver.1.5 Y.Shoji ADD End
      ,p_scheduled_end_date      => TRUNC(id_visit_date)     -- �\��I������
      ,p_actual_end_date         => id_visit_date            -- ���яI������
      ,p_source_object_type_code => 'PARTY'                  -- �\�[�X�I�u�W�F�N�g�R�[�h
      ,p_source_object_id        => in_party_id              -- �\�[�X�I�u�W�F�N�gID
      ,p_source_object_name      => iv_party_name            -- �\�[�X�I�u�W�F�N�g����
      ,p_attribute1              => iv_attribute1
      ,p_attribute2              => iv_attribute2
      ,p_attribute3              => iv_attribute3
      ,p_attribute4              => iv_attribute4
      ,p_attribute5              => iv_attribute5
      ,p_attribute6              => iv_attribute6
      ,p_attribute7              => iv_attribute7
      ,p_attribute8              => iv_attribute8
      ,p_attribute9              => iv_attribute9
      ,p_attribute10             => iv_attribute10
      ,p_attribute11             => iv_attribute11
      ,p_attribute12             => iv_attribute12
      ,p_attribute13             => iv_attribute13
      ,p_attribute14             => iv_attribute14
      ,p_attribute_category      => NULL
      ,x_task_id                 => on_task_id
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** ��������O ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API��O ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END create_task;
--
   /**********************************************************************************
   * Function Name    : update_task
   * Description      : �K��^�X�N�X�V����
   ***********************************************************************************/
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
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'update_task';
--
    -- �v���t�@�C���E�I�v�V����
    cv_prfnm_visit_task_name         CONSTANT VARCHAR2(100) := 'XXCSO1_VISIT_TASK_NAME'; -- �^�X�N����
    cv_prfnm_task_type_name          CONSTANT VARCHAR2(100) := 'XXCSO1_HHT_TASK_TYPE'; -- �^�X�N�^�C�v����
    cv_prfnm_task_status_closed_id   CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_CLOSED_ID'; -- �^�X�N�X�e�[�^�X
--
    -- ���b�Z�[�W�R�[�h
    cv_tkn_number_01           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- �v���t�@�C���擾�G���[
    cv_tkn_number_02           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00155';  -- ���o�G���[
--
    -- �g�[�N���R�[�h
    cv_tkn_err_msg             CONSTANT VARCHAR2(20) := 'ERR_MSG';
    cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
    cv_tkn_task_nm             CONSTANT VARCHAR2(20) := 'TASK_NAME';
--
    cv_task_type_id_nm         CONSTANT VARCHAR2(100) := '�^�X�N�^�C�vID';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_task_name               jtf_tasks_tl.task_name%TYPE;             -- �^�X�N����
    lv_task_type_name          jtf_task_types_tl.name%TYPE;                           -- �^�X�N�^�C�v����
    ln_task_type_id            jtf_tasks_b.task_type_id%TYPE;           -- �^�X�N�^�C�vID
    lv_task_status_id          VARCHAR2(100);                           -- �^�X�N�X�e�[�^�XID
    ln_task_status_id          jtf_tasks_b.task_status_id%TYPE;         -- �^�X�N�X�e�[�^�XID
    ln_obj_ver_num             NUMBER;                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
--
    -- API�߂�l
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- *** �^�X�N���̎擾 ***
    FND_PROFILE.GET(
                  cv_prfnm_visit_task_name
                 ,lv_task_name
    ); 
    -- �擾�����l���Ȃ��ꍇ
    IF (lv_task_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_prfnm_visit_task_name     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
--
    -- *** �^�X�N�^�C�vID�擾 ***
    -- �^�X�N�^�C�v���̎擾
    FND_PROFILE.GET(
                  cv_prfnm_task_type_name
                 ,lv_task_type_name
    ); 
    -- �擾�����l���Ȃ��ꍇ
    IF (lv_task_type_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_prfnm_task_type_name      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE g_process_expt;
    END IF;
    -- �^�X�N�^�C�vID�擾
    BEGIN
--
      SELECT jttv.task_type_id
      INTO ln_task_type_id
      FROM jtf_task_types_vl jttv
      WHERE jttv.name = lv_task_type_name
        AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(jttv.start_date_active, SYSDATE))
        AND TRUNC(NVL(jttv.end_date_active, SYSDATE));
    EXCEPTION
      WHEN OTHERS THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_task_type_id_nm      -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h1
                      ,iv_token_value2 => SQLERRM      -- �g�[�N���l1
                    );
       lv_errbuf := lv_errmsg;
       RAISE g_process_expt;
    END;
--
    -- *** �^�X�N�X�e�[�^�XID ***
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    IF (it_task_status_id IS NULL) THEN
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
      FND_PROFILE.GET(
                    cv_prfnm_task_status_closed_id
                   ,lv_task_status_id
      ); 
      -- �擾���s�����ꍇ
      IF (lv_task_status_id IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_prof_nm                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_prfnm_task_status_closed_id -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE g_process_expt;
      ELSE
        ln_task_status_id := TO_NUMBER(lv_task_status_id);
      END IF;
    /* 2009.07.16 K.Satomura 0000070�Ή� START */
    ELSE
      ln_task_status_id := it_task_status_id;
      --
    END IF;
    /* 2009.07.16 K.Satomura 0000070�Ή� END */
--
    ln_obj_ver_num := in_obj_ver_num;
--
    ------------------
    ---- API �N�� ----
    ------------------
    JTF_TASKS_PUB.UPDATE_TASK(
       p_api_version             => 1.0                      -- �o�[�W�����i���o�[
      ,p_task_id                 => in_task_id               -- �^�X�NID
      ,p_task_name               => lv_task_name             -- �^�X�N����
      ,p_task_type_id            => ln_task_type_id          -- �^�X�N�^�C�vID
      ,p_description             => iv_description           -- �E�v
      ,p_task_status_id          => ln_task_status_id        -- �^�X�N�X�e�[�^�X
      ,p_owner_type_code         => 'RS_EMPLOYEE'            -- �^�X�N���L�҃^�C�v�R�[�h
      ,p_owner_id                => in_resource_id           -- �^�X�N���L��ID
      /* 2009.05.22 K.Satomura T1_1080�Ή� START */
      ,p_customer_id             => in_party_id              -- �p�[�e�B�[ID
      /* 2009.05.22 K.Satomura T1_1080�Ή� END */
      ,p_scheduled_end_date      => TRUNC(id_visit_date)     -- �\��I������
      ,p_actual_end_date         => id_visit_date            -- ���яI������
      ,p_source_object_type_code => 'PARTY'                  -- �\�[�X�I�u�W�F�N�g�R�[�h
      ,p_source_object_id        => in_party_id              -- �\�[�X�I�u�W�F�N�gID
      ,p_source_object_name      => iv_party_name            -- �\�[�X�I�u�W�F�N�g����
      ,p_object_version_number   => ln_obj_ver_num
      ,p_attribute1              => iv_attribute1
      ,p_attribute2              => iv_attribute2
      ,p_attribute3              => iv_attribute3
      ,p_attribute4              => iv_attribute4
      ,p_attribute5              => iv_attribute5
      ,p_attribute6              => iv_attribute6
      ,p_attribute7              => iv_attribute7
      ,p_attribute8              => iv_attribute8
      ,p_attribute9              => iv_attribute9
      ,p_attribute10             => iv_attribute10
      ,p_attribute11             => iv_attribute11
      ,p_attribute12             => iv_attribute12
      ,p_attribute13             => iv_attribute13
      ,p_attribute14             => iv_attribute14
      ,p_attribute_category      => NULL
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** ��������O ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API��O ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END update_task;
--
   /**********************************************************************************
   * Function Name    : delete_task
   * Description      : �K��^�X�N�폜����
   ***********************************************************************************/
  PROCEDURE delete_task(
    in_task_id               IN  NUMBER,                 -- �^�X�NID
    in_obj_ver_num           IN  NUMBER,                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ����:0�A�x��:1�A�ُ�:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'delete_task';
--
    -- �g�[�N���R�[�h
    cv_tkn_err_msg             CONSTANT VARCHAR2(20) := 'ERR_MSG';
    cv_tkn_prof_nm             CONSTANT VARCHAR2(20) := 'PROF_NAME';
    cv_tkn_task_nm             CONSTANT VARCHAR2(20) := 'TASK_NAME';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- API�߂�l
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ------------------
    ---- API �N�� ----
    ------------------
    JTF_TASKS_PUB.DELETE_TASK(
       p_api_version             => 1.0                      -- �o�[�W�����i���o�[            
      ,p_object_version_number   => in_obj_ver_num           -- �I�u�W�F�N�g�o�[�W�����ԍ�
      ,p_task_id                 => in_task_id               -- �^�X�NID
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** ��������O ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API��O ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END delete_task;
/* 2009.10.23 D.Abe E_T4_00056�Ή� START */
--
   /**********************************************************************************
   * Function Name    : update_task2
   * Description      : �K��^�X�N�X�V�����Q�iATTRIBUTE15�̂ݍX�V�j
   ***********************************************************************************/
  PROCEDURE update_task2(
    in_task_id               IN  NUMBER,                 -- �^�X�NID
    in_obj_ver_num           IN  NUMBER,                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
    iv_attribute15           IN  VARCHAR2 DEFAULT jtf_task_utl.g_miss_char,  -- DFF15
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ����:0�A�x��:1�A�ُ�:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)   := 'update_task2';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_obj_ver_num             NUMBER;          -- �I�u�W�F�N�g�o�[�W�����ԍ�

    -- API�߂�l
    gx_return_status           VARCHAR2(100);
    gx_msg_count               NUMBER;
    gx_msg_data                VARCHAR2(100);
    wk_msg_data                VARCHAR2(2000);
    wk_msg_index_out           VARCHAR2(2000);
    wk_api_err_msg             VARCHAR2(2000);
    next_msg_index             NUMBER;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ln_obj_ver_num := in_obj_ver_num;
    ------------------
    ---- API �N�� ----
    ------------------
    JTF_TASKS_PUB.UPDATE_TASK(
       p_api_version             => 1.0                 -- �o�[�W�����i���o�[
      ,p_task_id                 => in_task_id          -- �^�X�NID
      ,p_object_version_number   => ln_obj_ver_num      -- �I�u�W�F�N�g�o�[�W�����ԍ�
      ,p_attribute15             => iv_attribute15
      ,x_return_status           => gx_return_status
      ,x_msg_count               => gx_msg_count
      ,x_msg_data                => gx_msg_data
    );
    IF gx_return_status = fnd_api.g_ret_sts_success THEN
      NULL;
    ELSE
      BEGIN
        <<error_msg_loop>>
        FOR i in 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.get(
                         p_msg_index      => i
                        ,p_encoded        => 'F'
                        ,p_data           => wk_msg_data
                        ,p_msg_index_out  => next_msg_index
          );
          wk_api_err_msg := wk_api_err_msg || ' ' || wk_msg_data;
        END LOOP error_msg_loop;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      RAISE g_api_expt;
    END IF;
  EXCEPTION
    -- *** ��������O ***
    WHEN g_process_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** API��O ***
    WHEN g_api_expt THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errmsg     := wk_api_err_msg;
      ov_errbuf     := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END update_task2;
/* 2009.10.23 D.Abe E_T4_00056�Ή� END */
--
END XXCSO_TASK_COMMON_PKG;
/
