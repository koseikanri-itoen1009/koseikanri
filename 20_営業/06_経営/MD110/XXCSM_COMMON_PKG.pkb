CREATE OR REPLACE PACKAGE BODY APPS.xxcsm_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcsm_common_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_CSM_���ʊ֐�
 * Version                : 1.2
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_yearplan_calender      P          �N�Ԍv��J�����_�擾�֐�
 *  get_employee_info          P          �]�ƈ����擾�֐�
 *  get_employee_foothold      P          �]�ƈ��ݐЋ��_�R�[�h�擾�֐�
 *  get_login_user_foothold    P          ���O�C�����[�U�[�ݐЋ��_�R�[�h�擾�֐�
 *  year_item_plan_security    P          �N�ԏ��i�v��Z�L�����e�B����p�֐�
 *  get_year_month             P          �N�x�Z�o�֐�
 *  get_kyoten_cd_lv6          P          ���_�R�[�h���X�g�擾�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-11-27    1.0  T.Tsukino       �V�K�쐬
 *  2009-04-09    1.1  M.Ohtsuki      �m��QT1_0416�n�Ɩ����t�ƃV�X�e�����t��r�̕s�
 *  2009-05-07    1.2  M.Ohtsuki      �m��QT1_0858�n���_�R�[�h���X�g�擾�����s��
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gv_msg_part         CONSTANT VARCHAR2(3)   := ' : ';
  gv_msg_cont         CONSTANT VARCHAR2(3)   := '.';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcsm_common_pkg';  -- �p�b�P�[�W��
  gv_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;               -- (���� = 0)
  gv_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;                 -- (�x�� = 1)
  gv_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;                -- (�ُ� = 2)
  gv_xxcsm_msg10012   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10012';
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** NULL�`�F�b�N   ***
  global_null_chk_expt      EXCEPTION;
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  /**********************************************************************************
   * Procedure  Name   : get_yearplan_calender
   * Description       : �N�Ԍv��J�����_�擾�֐�
   ***********************************************************************************/
  PROCEDURE get_yearplan_calender(
               id_comparison_date IN  DATE                                      -- ���t
              ,ov_status          OUT NOCOPY VARCHAR2                           -- ��������(0�F����A1�F�ُ�)
              ,on_active_year     OUT NUMBER                                    -- �Ώ۔N�x
              ,ov_retcode         OUT NOCOPY VARCHAR2                           -- ���^�[���R�[�h
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           -- �G���[���b�Z�[�W
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           -- ���[�U�[�E�G���[���b�Z�[�W
              )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_yearplan_calender';
    cv_carender_name    CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER';   -- �N�Ԕ̔��v��J�����_�[��
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_xxcsm_msg00005   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';
    cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_xxcsm_msg10005   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10005';
    cv_xxccp_msg10003   CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-10003';   --�ُ�I�����b�Z�[�W
    cv_xxccp_msg10013   CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-10013';   --�ُ�I�����b�Z�[�W
    cv_normal           CONSTANT VARCHAR2(1)   := '0';               -- ��������(���� = 0)
    cv_warn             CONSTANT VARCHAR2(1)   := '1';               -- ��������(�x�� = 1)
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_comparison_date  DATE;                        -- �p�����[�^�i�[�p
    ld_process_date     DATE;                        -- �Ɩ����t�i�[�p
    lv_carender_name    VARCHAR2(100);               -- �J�����_�[���i�[�p
    ln_active_year      NUMBER;                      -- �Ώ۔N�x�擾�p
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUT�p�����[�^���[�U�[�E�G���[���b�Z�[�W�i�[�p
--
    no_data_expt        EXCEPTION;
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
    --======================================================================
    -- IN�p�����[�^:���t�̒l��Null�̏ꍇ�A�Ɩ����t��ϐ��Ɋi�[
    -- ���̑��̏ꍇ�́A���̓p�����[�^�̓��t��ϐ��Ɋi�[���A�����Ɏg�p����B
    --======================================================================
    IF (id_comparison_date IS NULL) THEN
      ld_comparison_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_comparison_date := id_comparison_date;
    END IF;
--
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- �J�����_�[���̎擾
    lv_carender_name := FND_PROFILE.VALUE(cv_carender_name);
    DBMS_OUTPUT.PUT_LINE(lv_carender_name);
    -- �J�����_�[���̎擾���ł��Ȃ������ꍇ
    IF (lv_carender_name IS NULL) THEN   -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      RAISE no_data_expt;
    END IF;
    -- =====================================
    -- �Ώ۔N�x�擾����
    -- =====================================
    SELECT ffv.flex_value                                                       -- �Ώ۔N�x
    INTO   ln_active_year
    FROM   fnd_flex_value_sets  ffvs                                            -- �l�Z�b�g
          ,fnd_flex_values  ffv                                                 -- �l�Z�b�g����
    WHERE  ffvs.flex_value_set_name = lv_carender_name                          -- �J�����_�[���ŕR�t��
    AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--    AND   (ld_comparison_date BETWEEN  NVL(ffv.start_date_active, ld_process_date)
--                                          AND  NVL(ffv.end_date_active,ld_process_date))
--��������������������������������������������������������������������������������������������������
    AND   (ld_comparison_date BETWEEN  NVL(ffv.start_date_active,ld_comparison_date)
                                  AND  NVL(ffv.end_date_active,ld_comparison_date))
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
    AND  ffv.enabled_flag  = 'Y';
    -- �Ώ۔N�x�擾�����ɂāA�Ώ۔N�x���擾�ł��Ȃ������ꍇ
    IF (ln_active_year IS NULL) THEN
      RAISE NO_DATA_FOUND;
    END IF;
    ov_status      := cv_normal;
    ov_retcode     := gv_normal;          -- �������ʂɐ����Ԃ�
    on_active_year := ln_active_year;     -- �Ώ۔N�x���i�[
--
  EXCEPTION
--
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_xxccp_msg10013       -- ���b�Z�[�W�R�[�h
                            );
      ov_status      := cv_warn;
      on_active_year := NULL;
      ov_retcode     := gv_warn;
      ov_errbuf      := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg      := lv_errmsg;
    WHEN NO_DATA_FOUND THEN
      -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg10005      -- ���b�Z�[�W�R�[�h
                     );
      ov_status      := cv_warn;
      on_active_year := NULL;
      ov_retcode     := gv_warn;
      ov_errbuf      := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg      := lv_errmsg;
    WHEN no_data_expt THEN
      -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg00005   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_name    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_carender_name    -- �g�[�N���l1
                     );
      ov_status      := cv_warn;
      on_active_year := NULL;
      ov_retcode     := gv_warn;
      ov_errbuf      := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg      := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,4000);
      ov_retcode := gv_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,4000);
      ov_retcode := gv_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,4000);
      ov_retcode := gv_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END get_yearplan_calender;
--
  /**********************************************************************************
   * Procedure Name   : get_employee_info
   * Description      : �]�ƈ����擾�֐�
   ***********************************************************************************/
  PROCEDURE get_employee_info(
               iv_employee_code   IN  VARCHAR2                                  --�]�ƈ��R�[�h
              ,id_comparison_date IN  DATE                                      --���ߓ��Ɣ�r������t
              ,ov_capacity_code   OUT NOCOPY VARCHAR2                           --���i�R�[�h
              ,ov_duty_code       OUT NOCOPY VARCHAR2                           --�E���R�[�h
              ,ov_job_code        OUT NOCOPY VARCHAR2                           --�E��R�[�h
              ,ov_new_old_type    OUT NOCOPY VARCHAR2                           --�V���t���O�i1�F�V�A2�F���j
              ,ov_retcode         OUT NOCOPY VARCHAR2                           --���^�[���R�[�h
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           --�G���[���b�Z�[�W
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           --���[�U�[�E�G���[���b�Z�[�W
              )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_employee_info';
    cv_xxcsm_msg10006   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10006';
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_new              CONSTANT VARCHAR2(1)   := '1';
    cv_old              CONSTANT VARCHAR2(1)   := '2';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_comparison_date                DATE;
    lv_errbuf                         VARCHAR2(4000);
    lv_retcode                        VARCHAR2(4000);
    lv_errmsg                         VARCHAR2(4000);              -- OUT�p�����[�^���[�U�[�E�G���[���b�Z�[�W�i�[�p
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <get_employee_info_cur>
    CURSOR get_employee_info_cur(
      iv_employee_code VARCHAR2
    )
    IS
      SELECT paas.ass_attribute2  hatsurei_date          -- ���ߓ�
            ,ppf.attribute7       new_shikaku_code       -- ���i�R�[�h(�V)
            ,ppf.attribute9       old_shikaku_code       -- ���i�R�[�h(��)
            ,ppf.attribute15      new_syokumu_code       -- �E���R�[�h(�V)
            ,ppf.attribute17      old_shokumu_code       -- �E���R�[�h(��)
            ,ppf.attribute19      new_shokusyu_code      -- �E��R�[�h(�V)
            ,ppf.attribute21      old_shokusyu_code      -- �E��R�[�h(��)
      FROM  per_people_f  ppf            -- �]�ƈ��}�X�^
           ,per_all_assignments_f  paas  -- �]�ƈ��A�T�C�������g�}�X�^
      WHERE ppf.employee_number  =  iv_employee_code   --�]�ƈ��R�[�h�ŕR�t��
      AND   ppf.person_id = paas.person_id
      ;
    -- <�J�[�\����>���R�[�h�^
    get_employee_info_rec get_employee_info_cur%ROWTYPE;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
    --==============================
    -- IN�p�����[�^:NULL�`�F�b�N
    --==============================
    IF (iv_employee_code IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    --======================================================================
    -- IN�p�����[�^:���t�̒l��Null�̏ꍇ�A�Ɩ����t��ϐ��Ɋi�[
    -- ���̑��̏ꍇ�́A���̓p�����[�^�̓��t��ϐ��Ɋi�[���A�����Ɏg�p����B
    --======================================================================
    IF (id_comparison_date IS NULL) THEN
      ld_comparison_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_comparison_date := id_comparison_date;
    END IF;
    -- =====================================
    -- �]�ƈ����擾����
    -- =====================================
    OPEN get_employee_info_cur(iv_employee_code);
      FETCH get_employee_info_cur INTO get_employee_info_rec;
      IF get_employee_info_cur%NOTFOUND THEN
        RAISE NO_DATA_FOUND;
      END IF;
    CLOSE get_employee_info_cur;
    IF (get_employee_info_rec.hatsurei_date IS NULL)THEN
        RAISE NO_DATA_FOUND;
    END IF;
--
    --�擾�����u���ߓ��v�Ɠ��̓p�����[�^�u���ߓ��Ɣ�r������t�v�̔�r
    IF (get_employee_info_rec.hatsurei_date > TO_CHAR(ld_comparison_date, 'YYYYMMDD')) THEN
      ov_retcode       := gv_normal;                     -- ���^�[���R�[�h��0�i����j��Ԃ�
      ov_capacity_code := get_employee_info_rec.old_shikaku_code;                 -- ���i�R�[�h�ɏ�L�Ŏ擾�������i�R�[�h�i���j��Ԃ�
      ov_duty_code     := get_employee_info_rec.old_shokumu_code;                 -- �E���R�[�h�ɏ�L�Ŏ擾�����E���R�[�h�i���j��Ԃ�
      ov_job_code      := get_employee_info_rec.old_shokusyu_code;                -- �E��R�[�h�ɏ�L�Ŏ擾�����E��R�[�h�i���j��Ԃ�
      ov_new_old_type  := cv_old;
    ELSE
      ov_retcode       := gv_normal;                     -- ���^�[���R�[�h��0�i����j��Ԃ�
      ov_capacity_code := get_employee_info_rec.new_shikaku_code;                -- ���i�R�[�h�ɏ�L�Ŏ擾�������i�R�[�h�i�V�j��Ԃ�
      ov_duty_code     := get_employee_info_rec.new_syokumu_code;                -- �E���R�[�h�ɏ�L�Ŏ擾�����E���R�[�h�i�V�j��Ԃ�
      ov_job_code      := get_employee_info_rec.new_shokusyu_code;               -- �E��R�[�h�ɏ�L�Ŏ擾�����E��R�[�h�i�V�j��Ԃ�
      ov_new_old_type  := cv_new;
    END IF;
--
  EXCEPTION
--
  --�擾������0���̏ꍇ
    WHEN NO_DATA_FOUND THEN
      IF (get_employee_info_cur%ISOPEN) THEN
        CLOSE get_employee_info_cur;
      END IF;
       -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg10006       -- ���b�Z�[�W�R�[�h
                     );
      ov_retcode       := gv_warn;        --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_capacity_code := NULL;            --���i�R�[�h��NULL��Ԃ�
      ov_duty_code     := NULL;            --�E���R�[�h��NULL��Ԃ�
      ov_job_code      := NULL;            --�E��R�[�h��NULL��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULL�`�F�b�N
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => gv_xxcsm_msg10012       -- ���b�Z�[�W�R�[�h
                            );
      ov_retcode       := gv_warn;        --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_employee_info;
--
  /**********************************************************************************
   * Procedure Name   : get_employee_foothold
   * Description      : �]�ƈ��ݐЋ��_�R�[�h�擾�֐�
   ***********************************************************************************/
  PROCEDURE get_employee_foothold(
               iv_employee_code   IN  VARCHAR2                    --�]�ƈ��R�[�h
              ,id_comparison_date IN  DATE                        --���ߓ��Ɣ�r������t
              ,ov_foothold_code   OUT NOCOPY VARCHAR2             --���_�R�[�h
              ,ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���R�[�h
              ,ov_errbuf          OUT NOCOPY VARCHAR2             --�G���[���b�Z�[�W
              ,ov_errmsg          OUT NOCOPY VARCHAR2             --���[�U�[�E�G���[���b�Z�[�W
              )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_employee_foothold';
    cv_xxcsm_msg10007   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10007';
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_employee_code              VARCHAR2(1000);
    ld_comparison_date            DATE;
    lv_errbuf                     VARCHAR2(4000);
    lv_retcode                    VARCHAR2(4000);
    lv_errmsg                     VARCHAR2(4000);              -- OUT�p�����[�^���[�U�[�E�G���[���b�Z�[�W�i�[�p
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <get_employee_foothold_cur>
    CURSOR get_employee_foothold_cur(
      iv_employee_code VARCHAR2
    )
    IS
    SELECT paaf.ass_attribute2  hatsurei_date       -- ���ߓ�
          ,paaf.ass_attribute5  new_kyoten_code     -- ���_�R�[�h�i�V�j
          ,paaf.ass_attribute6  old_kyoten_code     -- ���_�R�[�h�i���j
    FROM  per_people_f  ppf            -- �]�ƈ��}�X�^
         ,per_all_assignments_f  paaf  -- �]�ƈ��A�T�C�������g�}�X�^
    WHERE ppf.employee_number  =  iv_employee_code  -- �]�ƈ��R�[�h�ŕR�t��
    AND   ppf.person_id = paaf.person_id
    ;
    -- <�J�[�\����>���R�[�h�^
    get_employee_foothold_rec get_employee_foothold_cur%ROWTYPE;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
    --==============================
    -- IN�p�����[�^:NULL�`�F�b�N
    --==============================
    IF (iv_employee_code IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    --======================================================================
    -- IN�p�����[�^:���t�̒l��Null�̏ꍇ�A�Ɩ����t��ϐ��Ɋi�[
    -- ���̑��̏ꍇ�́A���̓p�����[�^�̓��t��ϐ��Ɋi�[���A�����Ɏg�p����B
    --======================================================================
    IF (id_comparison_date IS NULL) THEN
      ld_comparison_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_comparison_date := id_comparison_date;
    END IF;
--
    -- =====================================
    -- �]�ƈ��ݐЋ��_�R�[�h�擾����
    -- =====================================
    OPEN get_employee_foothold_cur(iv_employee_code);
      FETCH get_employee_foothold_cur INTO get_employee_foothold_rec;
      IF get_employee_foothold_cur%NOTFOUND THEN
        RAISE NO_DATA_FOUND;
      END IF;
    CLOSE get_employee_foothold_cur;
    IF (get_employee_foothold_rec.hatsurei_date IS NULL) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
    --�擾�����u���ߓ�(YYYYMMDD)�v�Ɠ��̓p�����[�^�u���ߓ��Ɣ�r������t�v�̔�r
    IF (get_employee_foothold_rec.hatsurei_date > TO_CHAR(ld_comparison_date, 'YYYYMMDD')) THEN
      ov_retcode       := gv_normal;                  -- ���^�[���R�[�h��0�i����j��Ԃ�
      ov_foothold_code := get_employee_foothold_rec.old_kyoten_code;          -- ���_�R�[�h�ɏ�L�Ŏ擾�������_�R�[�h�i���j��Ԃ�
    ELSE
      ov_retcode       := gv_normal;                  -- ���^�[���R�[�h��0�i����j��Ԃ�
      ov_foothold_code := get_employee_foothold_rec.new_kyoten_code;          -- ���_�R�[�h�ɏ�L�Ŏ擾�������_�R�[�h�i�V�j��Ԃ�
    END IF;
--
  EXCEPTION
--
  --�擾������0���̏ꍇ
    WHEN NO_DATA_FOUND THEN
      IF (get_employee_foothold_cur%ISOPEN) THEN
        CLOSE get_employee_foothold_cur;
      END IF;
       -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg10007       -- ���b�Z�[�W�R�[�h
                     );
      ov_retcode       := gv_warn;    -- ���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_foothold_code := NULL;        -- ���_�R�[�h��NULL��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULL�`�F�b�N
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => gv_xxcsm_msg10012       -- ���b�Z�[�W�R�[�h
                            );
      ov_retcode       := gv_warn;        --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
--
  END get_employee_foothold;
--
  /**********************************************************************************
   * Procedure Name   : get_login_user_foothold
   * Description      : ���O�C�����[�U�[�ݐЋ��_�R�[�h�擾�֐�
   ***********************************************************************************/
  PROCEDURE get_login_user_foothold(
               in_user_id       IN NUMBER                                       --���[�UID
              ,ov_foothold_code OUT NOCOPY VARCHAR2                             --���_�R�[�h
              ,ov_employee_code OUT NOCOPY VARCHAR2                             --�]�ƈ��R�[�h
              ,ov_retcode       OUT NOCOPY VARCHAR2                             -- ���^�[���R�[�h
              ,ov_errbuf        OUT NOCOPY VARCHAR2                             --�G���[���b�Z�[�W
              ,ov_errmsg        OUT NOCOPY VARCHAR2                             --���[�U�[�E�G���[���b�Z�[�W
              )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_login_user_foothold';
    cv_xxcsm_msg10008          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10008';
    cv_xxcsm_msg10011          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10011';
    cv_xxcsm                   CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_tkn_jugyoin_cd          CONSTANT VARCHAR2(20) := 'JUGYOIN_CD';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_employee_number  per_people_f.employee_number%TYPE;
    lv_foothold_code    VARCHAR2(4000);
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUT�p�����[�^���[�U�[�E�G���[���b�Z�[�W�i�[�p
    --
    no_employee_date_expt EXCEPTION;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
    --==============================
    -- IN�p�����[�^:NULL�`�F�b�N
    --==============================
    IF (in_user_id IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    -- =====================================
    -- �]�ƈ��R�[�h�擾����
    -- =====================================
    SELECT  ppf.employee_number          -- �]�ƈ��R�[�h
    INTO    lt_employee_number
    FROM    fnd_user  fu                 -- ���[�U�}�X�^
           ,per_people_f  ppf            -- �]�ƈ��}�X�^
    WHERE   fu.user_id     =  in_user_id
    AND     fu.employee_id = ppf.person_id
    ;
    ov_employee_code := lt_employee_number;
    -- �擾��0���̏ꍇ
    IF (lt_employee_number IS NULL) THEN
      RAISE NO_DATA_FOUND;
    END IF;
  --
  --
    xxcsm_common_pkg.get_employee_foothold(
       iv_employee_code   => lt_employee_number      --�]�ƈ��R�[�h
      ,id_comparison_date => xxccp_common_pkg2.get_process_date   --�Ɩ����t���Ƃ��Ă���֐�
      ,ov_foothold_code   => lv_foothold_code
      ,ov_retcode         => lv_retcode
      ,ov_errbuf          => lv_errbuf
      ,ov_errmsg          => lv_errmsg
      );
    -- �]�ƈ��ݐЋ��_�R�[�h�擾�֐��ɂāA�f�[�^���擾�ł��������`�F�b�N����
    -- �ł��Ă��Ȃ������ꍇ�A�G���[�𔭐�������
    IF (lv_retcode <> gv_normal) THEN
      RAISE no_employee_date_expt;
    END IF;
    -- OUT�p�����[�^�Ɏ擾�����l���Z�b�g
    ov_foothold_code := lv_foothold_code;
    ov_retcode       := lv_retcode;
    ov_errbuf        := lv_errbuf;
    ov_errmsg        := lv_errmsg;
  --
  EXCEPTION
--
  --�擾������0���̏ꍇ
    WHEN NO_DATA_FOUND THEN
      -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg10008      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_jugyoin_cd
                     ,iv_token_value1 => in_user_id
                     );
      ov_retcode       := gv_warn;    --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_foothold_code := NULL;        --���_�R�[�h��NULL��Ԃ�
      ov_employee_code := NULL;        --�]�ƈ��R�[�h��NULL��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
    WHEN no_employee_date_expt THEN
       -- ���b�Z�[�W�擾�֐����G���[���b�Z�[�W���Z�b�g����
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_xxcsm_msg10011       -- ���b�Z�[�W�R�[�h
                            );
      ov_retcode       := gv_warn;    --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_foothold_code := NULL;        --���_�R�[�h��NULL��Ԃ�
      ov_employee_code := NULL;        --�]�ƈ��R�[�h��NULL��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULL�`�F�b�N
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => gv_xxcsm_msg10012       -- ���b�Z�[�W�R�[�h
                            );
      ov_retcode       := gv_warn;        --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,4000);
      ov_retcode := gv_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_login_user_foothold;
--
  /**********************************************************************************
   * Procedure  Name   : year_item_plan_security
   * Description       : �N�ԏ��i�v��Z�L�����e�B����p�֐�
   ***********************************************************************************/
  PROCEDURE year_item_plan_security(
               in_user_id          IN  NUMBER
              ,ov_lv6_kyoten_list  OUT NOCOPY VARCHAR2     --�����i1:�c�Ɗ��A2�F�c�ƊǗ�����ہA3�F���̑��j
              ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���R�[�h
              ,ov_errbuf           OUT NOCOPY VARCHAR2     --�G���[���b�Z�[�W
              ,ov_errmsg           OUT NOCOPY VARCHAR2     --���[�U�[�E�G���[���b�Z�[�W
              )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'year_item_plan_security';
    cv_no_flv_tag       CONSTANT VARCHAR2(100) := '3';
    cv_xxcsm_msg10009   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10009';
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';

--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_kyoten_cd        VARCHAR2(4000);
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUT�p�����[�^���[�U�[�E�G���[���b�Z�[�W�i�[�p
    --
    no_data_kyoten_expt EXCEPTION;
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <get_year_item_cur>
    CURSOR get_year_item_cur(
      in_user_id NUMBER
    )
    IS
      SELECT paaf.ass_attribute2  hatsurei_date   --���ߓ�
            ,paaf.ass_attribute5  new_kyoten_code --���_�R�[�h�i�V�j
            ,paaf.ass_attribute6  old_kyoten_code --���_�R�[�h�i���j
      FROM   fnd_user  fu
            ,per_all_assignments_f  paaf
      WHERE fu.user_id  =  in_user_id
      AND   fu.employee_id = paaf.person_id
      ;
    -- <�J�[�\����>���R�[�h�^
    get_year_item_rec get_year_item_cur%ROWTYPE;

--
    -- <get_dept_date_cur>
    CURSOR get_dept_date_cur(
      iv_kyoten_cd2 VARCHAR2
    )
    IS
      SELECT flv.tag
      FROM   fnd_lookup_values  flv
            ,xxcsm_loc_level_list_v  xlllv
      WHERE  flv.lookup_type  = 'XXCSM1_BUSINESS_DEPT'
      AND    flv.language     = USERENV('LANG')
      AND    flv.enabled_flag = 'Y'
      AND    NVL(flv.start_date_active,xxccp_common_pkg2.get_process_date)  <= xxccp_common_pkg2.get_process_date
      AND    NVL(flv.end_date_active,xxccp_common_pkg2.get_process_date)    >= xxccp_common_pkg2.get_process_date
      AND    flv.lookup_code  = DECODE(flv.attribute1 , 'L1' ,xlllv.cd_level1
                                                     , 'L2' ,xlllv.cd_level2
                                                     , 'L3' ,xlllv.cd_level3
                                                     , 'L4' ,xlllv.cd_level4
                                                     , 'L5' ,xlllv.cd_level5
                                                            ,xlllv.cd_level6)
      AND   iv_kyoten_cd2 = DECODE(xlllv.location_level , 'L6' ,xlllv.cd_level6
                                                        , 'L5' ,xlllv.cd_level5
                                                        , 'L4' ,xlllv.cd_level4
                                                        , 'L3' ,xlllv.cd_level3
                                                               ,xlllv.cd_level2)
      ;
    -- <�J�[�\����>���R�[�h�^
    get_dept_date_rec get_dept_date_cur%ROWTYPE;
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
    --==============================
    -- IN�p�����[�^:NULL�`�F�b�N
    --==============================
    IF (in_user_id IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    -- =====================================
    -- ���_�R�[�h�i�V/���j�E���ߓ��擾����
    -- =====================================
    OPEN get_year_item_cur(in_user_id);
    FETCH get_year_item_cur INTO get_year_item_rec;
    IF get_year_item_cur%NOTFOUND THEN
      RAISE no_data_kyoten_expt;
    END IF;
    CLOSE get_year_item_cur;
    IF (get_year_item_rec.hatsurei_date IS NULL) THEN
      RAISE no_data_kyoten_expt;
    END IF;
    -- =====================================
    -- ���_�R�[�h�Z�o����
    -- =====================================
    IF (get_year_item_rec.hatsurei_date > TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')) THEN
      lv_kyoten_cd := get_year_item_rec.old_kyoten_code;  --���_�R�[�h�i���j
    ELSE
      lv_kyoten_cd := get_year_item_rec.new_kyoten_code;  --���_�R�[�h�i�V)
    END IF;
    -- =====================================
    -- ������擾����
    -- =====================================
    OPEN get_dept_date_cur(lv_kyoten_cd);
    FETCH get_dept_date_cur INTO get_dept_date_rec;
    CLOSE get_dept_date_cur;
    --�o�̓p�����[�^����
    IF (get_dept_date_rec.tag IS NULL) THEN
      ov_lv6_kyoten_list := cv_no_flv_tag;
    ELSE
      ov_lv6_kyoten_list  := get_dept_date_rec.tag;
    END IF;
    ov_retcode          := gv_normal;
--
  EXCEPTION
--
  -- ���_�R�[�h�E���ߓ��̎擾���ł��Ȃ������ꍇ
    WHEN no_data_kyoten_expt THEN
      IF (get_year_item_cur%ISOPEN) THEN
        CLOSE get_year_item_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_xxcsm_msg10009      -- ���b�Z�[�W�R�[�h
                     );
      ov_retcode         := gv_warn;           --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf          := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg          := lv_errmsg;
--
    --NULL�`�F�b�N
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => gv_xxcsm_msg10012       -- ���b�Z�[�W�R�[�h
                            );
      ov_retcode       := gv_warn;        --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END year_item_plan_security;
--
  /**********************************************************************************
   * Procedure  Name   : get_year_month
   * Description       : �N�x�Z�o�֐�
   ***********************************************************************************/
  PROCEDURE get_year_month(
               iv_process_years IN VARCHAR2
              ,ov_year          OUT NOCOPY VARCHAR2
              ,ov_month         OUT NOCOPY VARCHAR2
              ,ov_retcode       OUT NOCOPY VARCHAR2
              ,ov_errbuf        OUT NOCOPY VARCHAR2
              ,ov_errmsg        OUT NOCOPY VARCHAR2
              )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_year_month';
    cv_gl_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';           -- ��v����ID
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_xxcsm_msg00005   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';
    cv_xxcsm_msg10001   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUT�p�����[�^���[�U�[�E�G���[���b�Z�[�W�i�[�p
    lv_gl_id            VARCHAR2(100);
    no_data_gl_expt     EXCEPTION;
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <get_year_month_cur>
    CURSOR get_year_month_cur(
      in_gl_id        NUMBER
     ,iv_process_year VARCHAR2
    )
    IS
    SELECT DISTINCT gp.period_year                 period_year
          ,TO_NUMBER(TO_CHAR(gp.start_date, 'MM')) start_date
    FROM   gl_sets_of_books gsob
          ,gl_periods       gp
    WHERE  gsob.set_of_books_id = in_gl_id
    AND    gsob.period_set_name = gp.period_set_name
    AND    TO_CHAR(gp.start_date,'YYYYMM') <= iv_process_year
    AND    TO_CHAR(gp.end_date,'YYYYMM') >= iv_process_year
    ;
    -- <�J�[�\����>���R�[�h�^
    get_year_month_rec get_year_month_cur%ROWTYPE;
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
    --==============================
    -- IN�p�����[�^:NULL�`�F�b�N
    --==============================
    IF (iv_process_years IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    -- =====================================
    -- �v���t�@�C���l�擾(FND_PROFILE.VALUE)
    -- =====================================
    lv_gl_id         := FND_PROFILE.VALUE(cv_gl_id);
    --
    --�v���t�@�C���l�擾���ł��Ȃ������ꍇ
    IF (lv_gl_id IS NULL) THEN
      RAISE no_data_gl_expt;
    END IF;
    -- =====================================
    -- �N�x�E���擾����
    -- =====================================
    OPEN get_year_month_cur(TO_NUMBER(lv_gl_id), iv_process_years);
    FETCH get_year_month_cur INTO get_year_month_rec;
    IF (get_year_month_cur%NOTFOUND) THEN
       RAISE NO_DATA_FOUND;
    END IF;
    CLOSE get_year_month_cur;
    IF (get_year_month_rec.period_year IS NULL
        OR get_year_month_rec.start_date IS NULL) THEN
        RAISE NO_DATA_FOUND;
    END IF;
    ov_year  := get_year_month_rec.period_year;
    ov_month := TO_CHAR(get_year_month_rec.start_date);
  EXCEPTION
--
  --�v���t�@�C���I�v�V�����l���擾�ł��Ȃ������ꍇ
    WHEN no_data_gl_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg00005                     -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name                     -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_gl_id                             -- �g�[�N���l1
                     );
      ov_year          := NULL;
      ov_month         := NULL;
      ov_retcode       := gv_warn;
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
  --�擾������0���̏ꍇ
    WHEN NO_DATA_FOUND THEN
      IF (get_year_month_cur%ISOPEN) THEN
        CLOSE get_year_month_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg10001                          -- ���b�Z�[�W�R�[�h
                     );
      ov_year          := NULL;
      ov_month         := NULL;
      ov_retcode       := gv_warn;           --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULL�`�F�b�N
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => gv_xxcsm_msg10012       -- ���b�Z�[�W�R�[�h
                            );
      ov_retcode       := gv_warn;        --���^�[���R�[�h��1�i�x���j��Ԃ�
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_year_month;
--
  /**********************************************************************************
   * Procedure  Name   : get_kyoten_cd_lv6
   * Description       : �c�ƕ���z���̋��_���X�g�擾
   ***********************************************************************************/
  PROCEDURE get_kyoten_cd_lv6(
               iv_kyoten_cd         IN VARCHAR2
              ,iv_kaisou            IN VARCHAR2
--//+ADD START 2009/05/07 T1_0858 M.Ohtsuki
              ,iv_subject_year      IN VARCHAR2
--//+ADD END   2009/05/07 T1_0858 M.Ohtsuki
              ,o_kyoten_list_tab    OUT g_kyoten_ttype
              ,ov_retcode           OUT NOCOPY VARCHAR2
              ,ov_errbuf            OUT NOCOPY VARCHAR2
              ,ov_errmsg            OUT NOCOPY VARCHAR2
              )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_kyoten_cd_lv6';     -- �v���O������
    cv_xxcsm            CONSTANT VARCHAR2(100)  := 'XXCSM';
    cv_xxcsm_msg00121   CONSTANT VARCHAR2(100)  := 'APP-XXCSM1-10121';
    cv_tkn_kyoten       CONSTANT VARCHAR2(100)  := 'KYOTEN';
    cv_tkn_kaisou       CONSTANT VARCHAR2(100)  := 'KAISOU';

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_level_6               CONSTANT VARCHAR2(2)    := 'L6';                   -- �K�wL6
    cv_level_5               CONSTANT VARCHAR2(2)    := 'L5';                   -- �K�wL5
    cv_level_4               CONSTANT VARCHAR2(2)    := 'L4';                   -- �K�wL4
    cv_level_3               CONSTANT VARCHAR2(2)    := 'L3';                   -- �K�wL3
    cv_level_2               CONSTANT VARCHAR2(2)    := 'L2';                   -- �K�wL2
    cv_level_1               CONSTANT VARCHAR2(2)    := 'L1';                   -- �K�wL1
    cv_level_all             CONSTANT VARCHAR2(3)    := 'ALL';                  -- �S�Ώ�
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_kaisou     VARCHAR2(5);
    ln_all_flag   NUMBER;
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- **���̓p�����[�^�őS���_���w�肳�ꂽ�ꍇ�A1���߂����B
    CURSOR all_loc_chk_cur(
      iv_all_loc_value   VARCHAR2
      )
    IS
      SELECT COUNT(1)
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type = 'XXCSM1_FORM_PARAMETER_VALUE'
      AND    flv.language = USERENV('LANG')
      AND    flv.enabled_flag = 'Y'
      AND    NVL(flv.start_date_active,xxccp_common_pkg2.get_process_date)  <= xxccp_common_pkg2.get_process_date
      AND    NVL(flv.end_date_active,xxccp_common_pkg2.get_process_date)    >= xxccp_common_pkg2.get_process_date
      AND    flv.lookup_code = iv_all_loc_value
      ;
    -- ============================
    -- ���[�J���e�[�u����`
    -- ============================
    l_get_loc_tab g_kyoten_ttype;    --�f�[�^�擾�p�ϐ�
    -- ============================
    -- ���[�J���E��O
    -- ============================
    no_data_kyoten_expt     EXCEPTION;
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_all_flag  :=  0;
    --���̓p�����[�^�̕���R�[�h�w��or�S���_�Ώۂ�����B
    IF (iv_kaisou = cv_level_6) THEN
      -- **�S���_���w�肳���̂͊K�w��L6�̏ꍇ�݂̂̂��߁A���̑��̏ꍇ�́A�S���_�̃`�F�b�N���s��Ȃ��B
      OPEN all_loc_chk_cur(iv_kyoten_cd);
      FETCH all_loc_chk_cur INTO ln_all_flag;
      CLOSE all_loc_chk_cur;
    END IF;
--
    --����R�[�h�w��̏ꍇ�ƑS���_�ΏۂƂ���ꍇ��
    --SQL�ɓn���p�����[�^�𐧌�
    IF (ln_all_flag > 0) THEN
      lv_kaisou  := cv_level_all;
    ELSE
      lv_kaisou  := iv_kaisou;
    END IF;
    --=======================================================================
    --���̓p�����[�^�̕���R�[�h�ƊK�w����A�z���̋��_�𒊏o�B
    --�S���_�̏ꍇ�A�S�Ă̋��_�R�[�h���擾���܂��B
    --�z���Ɏq��������R�[�h�w��̏ꍇ�A���̕���R�[�h�z���ɕR�t�����_�R�[�h���擾���܂��B
    --���_�R�[�h�w��̏ꍇ�A�w�肳�ꂽ���_�R�[�h�݂̂��擾���܂��B
    --=======================================================================
    SELECT xlnlv.base_code       AS kyoten_cd    --���_�R�[�h
          ,xlnlv.base_name       AS kyoten_nm    --���_����
    BULK COLLECT INTO l_get_loc_tab
    FROM   xxcsm_loc_name_list_v     xlnlv       --���喼�̃r���[
          ,xxcsm_loc_level_list_v    xlllv       --����ꗗ�r���[
    WHERE  iv_kyoten_cd = DECODE(DECODE(lv_kaisou, cv_level_6, xlllv.location_level
                                                             , lv_kaisou)
                                ,cv_level_6,xlllv.cd_level6
                                ,cv_level_5,xlllv.cd_level5
                                ,cv_level_4,xlllv.cd_level4
                                ,cv_level_3,xlllv.cd_level3
                                ,cv_level_2,xlllv.cd_level2
                                ,cv_level_1,xlllv.cd_level1
                                ,cv_level_all,iv_kyoten_cd    --'ALL'�̏ꍇ�́A�����𖳌���������B
                                ,NULL)
    AND    xlnlv.base_code = DECODE(xlllv.location_level
                                   ,cv_level_6,xlllv.cd_level6
                                   ,cv_level_5,xlllv.cd_level5
                                   ,cv_level_4,xlllv.cd_level4
                                   ,cv_level_3,xlllv.cd_level3
                                   ,cv_level_2,xlllv.cd_level2
                                   ,cv_level_1,xlllv.cd_level1
                                   ,NULL)
--// ADD START 2009/05/07 T1_0858 M.Ohtsuki
      AND EXISTS
          (SELECT 'X'
           FROM   xxcsm_item_plan_result   xipr                                                     -- ���i�v��p�̔�����
           WHERE  (xipr.subject_year = (TO_NUMBER(iv_subject_year) - 1)                             -- ���̓p�����[�^��1�N�O�̃f�[�^
                OR xipr.subject_year = (TO_NUMBER(iv_subject_year) - 2))                            -- ���̓p�����[�^��2�N�O�̃f�[�^
           AND     xipr.location_cd  = xlnlv.base_code)
--// ADD END   2009/05/07 T1_0858 M.Ohtsuki
    ;
    -- ���o�R�[�h�̌�����0���̏ꍇ
    IF (l_get_loc_tab.COUNT = 0) THEN
      RAISE no_data_kyoten_expt;
    END IF;
--
    --OUT�p�����[�^�Ƀf�[�^��߂��B
    o_kyoten_list_tab   := l_get_loc_tab;
--
  EXCEPTION
    WHEN no_data_kyoten_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                             -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg00121                    -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_kyoten                        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => iv_kyoten_cd                         -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_kaisou                        -- �g�[�N���R�[�h2
                    ,iv_token_value2 => iv_kaisou                            -- �g�[�N���l2
                     );
      ov_retcode          := gv_warn;
      ov_errbuf           := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg           := lv_errmsg;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_kyoten_cd_lv6;
END xxcsm_common_pkg;
/
